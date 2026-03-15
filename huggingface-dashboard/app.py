# Roo Crypto Intelligence Dashboard
# Streamlit app for visualizing TrojanLogic4H scan data

import streamlit as st
import pandas as pd
import plotly.express as px
import requests
import json

# Page config
st.set_page_config(
    page_title="Roo Crypto Intelligence",
    page_icon="📊",
    layout="wide"
)

st.title("📊 Roo Crypto Intelligence Dashboard")
st.markdown("*Real-time analysis from TrojanLogic4H scans*")

# Data URL
LATEST_URL = "https://raw.githubusercontent.com/impro58-oss/rooquest1/master/data/crypto/crypto_latest.json"

@st.cache_data(ttl=300)
def load_data():
    """Load data from GitHub."""
    response = requests.get(LATEST_URL, timeout=15)
    response.raise_for_status()
    content = response.content.decode('utf-8-sig')
    return json.loads(content)

# Load data
try:
    data = load_data()
    st.sidebar.success("✅ Live data loaded")
except Exception as e:
    st.error(f"Error loading data: {e}")
    st.stop()

last_update = data.get('scan_timestamp', 'Unknown')
st.sidebar.info(f"Last Update: {last_update}")

# Convert to DataFrame
results = data.get('results', [])
df = pd.DataFrame(results)

if len(df) == 0:
    st.warning("No scan results found.")
    st.stop()

# Summary metrics
col1, col2, col3, col4 = st.columns(4)

with col1:
    st.metric("Total Symbols", len(df))
with col2:
    long_count = len(df[df['signal'].str.upper() == 'LONG'])
    st.metric("LONG Signals", long_count)
with col3:
    short_count = len(df[df['signal'].str.upper() == 'SHORT'])
    st.metric("SHORT Signals", short_count)
with col4:
    high_conf = len(df[df['confidence'] >= 0.65])
    st.metric("High Confidence", high_conf)

# Charts
st.markdown("---")
col1, col2 = st.columns(2)

with col1:
    st.subheader("Signal Distribution")
    signal_counts = df['signal'].value_counts()
    colors_map = {'LONG': '#00cc00', 'SHORT': '#ff4444', 'HOLD': '#888888'}
    fig = px.pie(
        values=signal_counts.values,
        names=signal_counts.index,
        color=signal_counts.index.str.upper(),
        color_discrete_map=colors_map
    )
    st.plotly_chart(fig, use_container_width=True)

with col2:
    st.subheader("Confidence Distribution")
    fig = px.histogram(
        df, x='confidence', nbins=20,
        labels={'confidence': 'Confidence Score'}
    )
    st.plotly_chart(fig, use_container_width=True)

# Top opportunities
st.markdown("---")
st.subheader("🎯 Top Opportunities")

opportunities = df[
    (df['signal'].str.upper().isin(['LONG', 'SHORT'])) & 
    (df['confidence'] >= 0.45)
].sort_values('confidence', ascending=False).head(10)

if len(opportunities) > 0:
    display_df = opportunities[['symbol', 'signal', 'confidence', 'price', 'strategy']].copy()
    display_df['confidence'] = (display_df['confidence'] * 100).round(1).astype(str) + '%'
    display_df['price'] = '$' + display_df['price'].round(2).astype(str)
    st.dataframe(display_df, use_container_width=True)
else:
    st.info("No high-confidence opportunities found.")

# Raw data
st.markdown("---")
with st.expander("View Raw Data"):
    st.dataframe(df, use_container_width=True)

# Footer
st.markdown("---")
st.markdown(
    "<div style='text-align: center; color: #666;'>"
    "Data source: GitHub | Strategy: TrojanLogic4H"
    "</div>",
    unsafe_allow_html=True
)
