"""
clean_data.py
-------------
Cleans the raw Amazon e-commerce sales CSV and outputs a clean version
ready to import into Power BI.

Usage:
    python clean_data.py

Input  : data/ecommerce_sales.csv
Output : data/ecommerce_sales_clean.csv
"""

import pandas as pd
import os

RAW_PATH   = "data/ecommerce_sales.csv"
CLEAN_PATH = "data/ecommerce_sales_clean.csv"


def load(path):
    print(f"Loading data from {path}...")
    df = pd.read_csv(path, low_memory=False)
    print(f"  Raw rows: {len(df):,}  |  Columns: {len(df.columns)}")
    return df


def clean(df):
    print("\nCleaning...")

    # 1. Drop unused / junk columns
    drop_cols = ["index", "Unnamed: 22", "promotion-ids", "fulfilled-by",
                 "currency", "ASIN", "SKU"]
    df.drop(columns=[c for c in drop_cols if c in df.columns], inplace=True)

    # 2. Rename columns to snake_case for consistency
    df.columns = (
        df.columns
        .str.strip()
        .str.lower()
        .str.replace(" ", "_")
        .str.replace("-", "_")
    )

    # 3. Parse dates
    df["date"] = pd.to_datetime(df["date"], format="%m-%d-%y", errors="coerce")

    # 4. Drop rows with no revenue or invalid dates
    before = len(df)
    df = df.dropna(subset=["amount", "date"])
    df = df[df["amount"] > 0]
    print(f"  Dropped {before - len(df):,} rows with missing amount/date")

    # 5. Drop rows with missing location
    df = df.dropna(subset=["ship_city", "ship_state"])

    # 6. Derive useful time columns
    df["month"]      = df["date"].dt.to_period("M").astype(str)   # e.g. 2022-04
    df["month_name"] = df["date"].dt.strftime("%B %Y")             # e.g. April 2022
    df["week"]       = df["date"].dt.isocalendar().week.astype(int)
    df["day_name"]   = df["date"].dt.day_name()

    # 7. Normalise status into a simpler label
    def simplify_status(s):
        s = str(s).lower()
        if "cancelled" in s:            return "Cancelled"
        if "delivered" in s:            return "Delivered"
        if "returned" in s:             return "Returned"
        if "lost" in s:                 return "Lost"
        if "damaged" in s:              return "Damaged"
        if "out for delivery" in s:     return "Out for Delivery"
        if "shipped" in s:              return "Shipped"
        if "pending" in s:              return "Pending"
        return "Other"

    df["status_simple"] = df["status"].apply(simplify_status)

    # 8. Standardise category casing
    df["category"] = df["category"].str.strip().str.title()

    # 9. Flag B2B vs B2C
    df["customer_type"] = df["b2b"].map({True: "B2B", False: "B2C"})

    # 10. Round amount
    df["amount"] = df["amount"].round(2)

    print(f"  Clean rows: {len(df):,}")
    return df


def summary(df):
    print("\n── Quick summary ───────────────────────────────────────")
    print(f"  Date range  : {df['date'].min().date()} → {df['date'].max().date()}")
    print(f"  Total revenue: ₹{df['amount'].sum():,.2f}")
    print(f"  Orders       : {df['order_id'].nunique():,}")
    print(f"  Categories   : {sorted(df['category'].unique())}")
    print(f"  States       : {df['ship_state'].nunique()} unique")
    print("────────────────────────────────────────────────────────")


def save(df, path):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    df.to_csv(path, index=False)
    print(f"\nSaved clean data → {path}")


if __name__ == "__main__":
    df = load(RAW_PATH)
    df = clean(df)
    summary(df)
    save(df, CLEAN_PATH)
