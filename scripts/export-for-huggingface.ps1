# export-for-huggingface.ps1
# Exports all data and prepares for Hugging Face Spaces deployment

$DataDir = "$env:USERPROFILE\.openclaw\workspace\data"
$RepoDir = "$env:USERPROFILE\.openclaw\workspace\huggingface-dashboard"

# Create repo directory
if (!(Test-Path $RepoDir)) {
    New-Item -ItemType Directory -Path $RepoDir -Force | Out-Null
}

Write-Host "Preparing data for Hugging Face..." -ForegroundColor Cyan

# Run data exporter
& "$env:USERPROFILE\.openclaw\workspace\scripts\data-exporter.ps1"

# Copy files to repo
Copy-Item "$DataDir\*.json" $RepoDir -Force
Copy-Item "$DataDir\*.html" $RepoDir -Force
Copy-Item "$DataDir\README.md" $RepoDir -Force

# Create app.py for Hugging Face Spaces
$AppPy = @"
import gradio as gr
import json
from datetime import datetime

def load_data():
    try:
        with open('dashboard-data.json', 'r') as f:
            return json.load(f)
    except:
        return None

def create_dashboard():
    data = load_data()
    if not data:
        return "Error loading data"
    
    portfolio = data.get('portfolio', {})
    
    # Stats
    total_invested = portfolio.get('totalInvested', 0)
    total_current = portfolio.get('totalCurrent', 0)
    total_pnl = portfolio.get('totalPnL', 0)
    positions = portfolio.get('totalPositions', 0)
    
    pnl_pct = (total_pnl / total_invested * 100) if total_invested > 0 else 0
    
    html = f'''
    <div style="font-family: Arial, sans-serif; padding: 20px;">
        <h1>Polymarket Trading Dashboard</h1>
        <p>Last Updated: {data.get('lastUpdated', 'Unknown')}</p>
        
        <div style="display: grid; grid-template-columns: repeat(4, 1fr); gap: 20px; margin: 20px 0;">
            <div style="background: #1a1a2a; padding: 20px; border-radius: 10px;">
                <h3>Total Invested</h3>
                <p style="font-size: 24px;">${total_invested:.2f} USDC</p>
            </div>
            
            <div style="background: #1a1a2a; padding: 20px; border-radius: 10px;">
                <h3>Current Value</h3>
                <p style="font-size: 24px;">${total_current:.2f} USDC</p>
            </div>
            
            <div style="background: #1a1a2a; padding: 20px; border-radius: 10px;">
                <h3>Total P&L</h3>
                <p style="font-size: 24px; color: {'#4ade80' if total_pnl >= 0 else '#f87171'};">
                    {'+' if total_pnl >= 0 else ''}{total_pnl:.2f} USDC ({pnl_pct:.2f}%)
                </p>
            </div>
            
            <div style="background: #1a1a2a; padding: 20px; border-radius: 10px;">
                <h3>Active Positions</h3>
                <p style="font-size: 24px;">{positions}</p>
            </div>
        </div>
        
        <h2>Positions</h2>
        <table style="width: 100%; border-collapse: collapse;">
            <thead>
                <tr style="background: #2a2a3a;">
                    <th style="padding: 10px; text-align: left;">Market</th>
                    <th style="padding: 10px; text-align: left;">Outcome</th>
                    <th style="padding: 10px; text-align: left;">Shares</th>
                    <th style="padding: 10px; text-align: left;">P&L</th>
                </tr>
            </thead>
            <tbody>
    '''
    
    for pos in portfolio.get('positions', []):
        pnl = pos.get('pnl', 0)
        html += f'''
                <tr style="border-bottom: 1px solid #2a2a3a;">
                    <td style="padding: 10px;"><a href="{pos.get('marketUrl', '#')}" target="_blank">{pos.get('market', 'Unknown')}</a></td>
                    <td style="padding: 10px;">{pos.get('outcome', 'Unknown')}</td>
                    <td style="padding: 10px;">{pos.get('shares', 0):.2f}</td>
                    <td style="padding: 10px; color: {'#4ade80' if pnl >= 0 else '#f87171'};">
                        {'+' if pnl >= 0 else ''}{pnl:.2f} USDC
                    </td>
                </tr>
        '''
    
    html += '''
            </tbody>
        </table>
        
        <p><a href="https://polymarket.com/portfolio" target="_blank" 
           style="background: #667eea; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px;">
           View on Polymarket
        </a></p>
    </div>
    '''
    
    return html

# Create Gradio interface
with gr.Blocks(title="Polymarket Dashboard") as demo:
    gr.HTML(create_dashboard)
    
    # Auto-refresh every 5 minutes
    gr.Timer(300).tick(lambda: create_dashboard(), outputs=gr.HTML())

if __name__ == "__main__":
    demo.launch()
"@

$AppPy | Out-File "$RepoDir\app.py" -Encoding utf8

# Create requirements.txt
$Requirements = @"
gradio>=4.0.0
"@

$Requirements | Out-File "$RepoDir\requirements.txt" -Encoding utf8

Write-Host "`nHugging Face dashboard prepared!" -ForegroundColor Green
Write-Host "Location: $RepoDir" -ForegroundColor Cyan
Write-Host "`nTo deploy:" -ForegroundColor Yellow
Write-Host "  1. Create new Space on Hugging Face" -ForegroundColor White
Write-Host "  2. Upload these files:" -ForegroundColor White
Write-Host "     - app.py" -ForegroundColor Gray
Write-Host "     - requirements.txt" -ForegroundColor Gray
Write-Host "     - *.json data files" -ForegroundColor Gray
Write-Host "  3. Space will auto-update when data changes" -ForegroundColor White
