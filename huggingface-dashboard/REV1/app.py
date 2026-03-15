# Roo Intelligence Dashboard - UNIFIED
# Shows both Crypto and Polymarket data on one page

import streamlit as st
import pandas as pd
import plotly.express as px
import requests
import json
from datetime import datetime

# Page config
st.set_page_config(
    page_title="Roo Intelligence Dashboard",
    page_icon="📊",
    layout="wide"
)

st.title("📊 Roo Intelligence Dashboard")
st.markdown("*Crypto + Polymarket opportunities in one view*")

# Data URLs
CRYPTO_URL = "https://raw.githubusercontent.com/impro58-oss/rooquest1/master/data/crypto/crypto_latest.json"
POLY_URL = "https://raw.githubusercontent.com/impro58-oss/rooquest1/master/data/polymarket/polymarket_latest.json"

@st.cache_data(ttl=300)
def load_crypto_data():
    """Load crypto data from GitHub."""
    try:
        response = requests.get(CRYPTO_URL, timeout=15)
        response.raise_for_status()
        content = response.content.decode('utf-8-sig')
        return json.loads(content)
    except:
        return None

@st.cache_data(ttl=300)
def load_polymarket_data():
    """Load Polymarket data from GitHub."""
    try:
        response = requests.get(POLY_URL, timeout=15)
        response.raise_for_status()
        content = response.content.decode('utf-8-sig')
        return json.loads(content)
    except:
        return None

# Load both datasets
crypto_data = load_crypto_data()
poly_data = load_polymarket_data()

# Sidebar info
st.sidebar.header("Data Status")
if crypto_data:
    st.sidebar.success("✅ Crypto data loaded")
    st.sidebar.info(f"Last update: {crypto_data.get('scan_timestamp', 'Unknown')}")
else:
    st.sidebar.warning("⚠️ Crypto data unavailable")

if poly_data:
    st.sidebar.success("✅ Polymarket data loaded")
    st.sidebar.info(f"Last update: {poly_data.get('timestamp', 'Unknown')}")
else:
    st.sidebar.warning("⚠️ Polymarket data unavailable")

# ==================== CRYPTO SECTION ====================
st.markdown("---")
st.header("🪙 Crypto Intelligence")

if crypto_data:
    results = crypto_data.get('results', [])
    df_crypto = pd.DataFrame(results)
    
    if len(df_crypto) > 0:
        # Metrics
        col1, col2, col3, col4 = st.columns(4)
        with col1:
            st.metric("Symbols", len(df_crypto))
        with col2:
            longs = len(df_crypto[df_crypto['signal'].str.upper() == 'LONG'])
            st.metric("LONG", longs)
        with col3:
            shorts = len(df_crypto[df_crypto['signal'].str.upper() == 'SHORT'])
            st.metric("SHORT", shorts)
        with col4:
            high_conf = len(df_crypto[df_crypto['confidence'] >= 0.65])
            st.metric("High Conf", high_conf)
        
        # Top crypto opportunities
        st.subheader("🎯 Top Crypto Opportunities")
        crypto_opp = df_crypto[
            (df_crypto['signal'].str.upper().isin(['LONG', 'SHORT'])) & 
            (df_crypto['confidence'] >= 0.45)
        ].sort_values('confidence', ascending=False).head(5)
        
        if len(crypto_opp) > 0:
            display = crypto_opp[['symbol', 'signal', 'confidence', 'price', 'strategy']].copy()
            display['confidence'] = (display['confidence'] * 100).round(1).astype(str) + '%'
            display['price'] = '$' + display['price'].round(2).astype(str)
            st.dataframe(display, use_container_width=True)
        else:
            st.info("No high-confidence crypto opportunities")
        
        # Raw crypto data
        with st.expander("View Crypto Raw Data"):
            st.dataframe(df_crypto, use_container_width=True)
else:
    st.error("Crypto data unavailable. Check back later.")

# ==================== POLYMARKET SECTION ====================
st.markdown("---")
st.header("🎲 Polymarket Opportunities")

if poly_data:
    bets = poly_data.get('hot_bets', [])
    df_poly = pd.DataFrame(bets)
    
    if len(df_poly) > 0:
        # Metrics
        col1, col2, col3 = st.columns(3)
        with col1:
            st.metric("Total Opportunities", len(df_poly))
        with col2:
            close_calls = len(df_poly[df_poly['EdgeType'] == 'CLOSE_CALL'])
            st.metric("Close Calls", close_calls)
        with col3:
            categories = df_poly['Category'].nunique()
            st.metric("Categories", categories)
        
        # Category breakdown
        st.subheader("📊 Opportunities by Category")
        cat_counts = df_poly['Category'].value_counts()
        fig = px.bar(
            x=cat_counts.index,
            y=cat_counts.values,
            labels={'x': 'Category', 'y': 'Count'},
            title="Hot Bets by Category"
        )
        st.plotly_chart(fig, use_container_width=True)
        
        # Top Polymarket opportunities
        st.subheader("🎯 Top Polymarket Opportunities")
        
        # Sort by closest to 50% (most uncertain/opportunity)
        df_poly['distance_from_50'] = abs(df_poly['OddsNum'] - 50)
        top_poly = df_poly.sort_values('distance_from_50').head(10)
        
        for _, bet in top_poly.iterrows():
            with st.container():
                col1, col2 = st.columns([3, 1])
                with col1:
                    st.markdown(f"**[{bet['Category'].upper()}]** {bet['Name']}")
                    st.markdown(f"📊 Odds: {bet['Odds']} | Type: {bet['EdgeType']}")
                with col2:
                    st.markdown(f"[View Market]({bet['Url']})")
                st.markdown("---")
        
        # Raw Polymarket data
        with st.expander("View Polymarket Raw Data"):
            st.dataframe(df_poly, use_container_width=True)
    else:
        st.info("No hot Polymarket opportunities found")
else:
    st.error("Polymarket data unavailable. Check back later.")

# Footer
st.markdown("---")
st.markdown(
    "<div style='text-align: center; color: #666;'>"
    "Crypto: TrojanLogic4H | Polymarket: Hourly Scanner | Data: GitHub"
    "</div>",
    unsafe_allow_html=True
)
