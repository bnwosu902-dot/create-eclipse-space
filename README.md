# CreateEclipse - Decentralized Media Licensing Platform

A revolutionary blockchain-based platform for creators to monetize and protect their intellectual property through dynamic smart contracts and automated royalty distribution.

## Overview

CreateEclipse transforms traditional media licensing into a transparent, creator-centric marketplace with:

- **Dynamic Licensing**: Flexible license types (Personal, Commercial, Exclusive, Creative Commons Plus)
- **Adaptive Pricing**: Real-time pricing based on content virality and demand
- **Automated Royalties**: Multi-party splits with instant payment distribution
- **IP Protection**: AI-powered infringement detection and reporting
- **Creative Staking**: Fan investment mechanism for emerging creators
- **Creator Reputation**: Track record system for building creator credibility

## Features

### For Creators
- Register content with IPFS storage and AI fingerprinting
- Set granular usage rights and licensing terms
- Automatic royalty distribution to collaborators
- Real-time analytics and viral score tracking
- Copyright infringement monitoring and resolution

### For Licensees
- Purchase licenses with transparent pricing
- Duration-based access control
- Clear usage rights documentation
- Automated license validation

### For Supporters
- Stake on promising creators
- Earn returns based on licensing success
- Support emerging talent

## Smart Contract Functions

### Content Management
- `register-content` - Register new media content
- `deactivate-content` - Remove content from marketplace
- `update-viral-score` - Update performance metrics

### Licensing
- `purchase-license` - Buy content license
- `revoke-license` - Creator revokes active license
- `is-license-valid` - Check license validity

### Royalties & Staking
- `add-royalty-split` - Add collaborator revenue share
- `stake-on-creator` - Invest in creator success

### IP Protection
- `report-infringement` - Flag copyright violations
- `resolve-infringement` - Mark infringement as resolved

### Analytics
- `get-content-analytics` - View performance metrics
- `get-creator-reputation` - Check creator track record
- `calculate-dynamic-price` - Get current pricing

## Installation
```bash
# Clone the repository
git clone https://github.com/yourusername/create-eclipse

# Navigate to project
cd create-eclipse

# Check contract syntax
clarinet check

# Run local devnet
clarinet integrate
```

## Usage Example
```clarity
;; Register content as creator
(contract-call? .create-eclipse register-content 
    "My Amazing Song"
    "QmXxXxXx..." 
    0x1234567890abcdef
    u1000000) ;; 1 STX base price

;; Purchase license
(contract-call? .create-eclipse purchase-license 
    u1 ;; content-id
    u2 ;; commercial license
    u52560 ;; ~1 year in blocks
    "Commercial use with attribution")

;; Add collaborator split
(contract-call? .create-eclipse add-royalty-split 
    u1 
    'SP2COLLABORATOR...
    u30) ;; 30% split
```

## Technical Architecture

- **Blockchain**: Stacks (Clarity smart contracts)
- **Storage**: IPFS for media files
- **Pricing**: Dynamic algorithm based on viral metrics
- **Security**: Zero-knowledge proofs for analytics
- **Fees**: 5% platform fee (configurable)

## Contributing

Contributions welcome! Please submit pull requests or open issues for bugs and feature requests.

