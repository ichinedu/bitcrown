# BitCrown Protocol - Sovereign Bitcoin Liquidity Engine

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Clarity Version](https://img.shields.io/badge/clarity-v3-green.svg)](https://book.clarity-lang.org/)
[![Stacks Network](https://img.shields.io/badge/network-stacks-purple.svg)](https://stacks.co/)

## Overview

BitCrown is a sophisticated Bitcoin-collateralized lending protocol that transforms idle sBTC holdings into productive capital through intelligent yield strategies and over-collateralized lending markets built natively on the Stacks Layer-2 blockchain. The protocol offers institutional-grade lending infrastructure where Bitcoin holders maintain custody while accessing deep liquidity pools.

### Key Features

- **🏦 Bitcoin-Native Lending**: Collateralize sBTC to borrow STX tokens
- **💰 Yield Generation**: Earn competitive returns by providing STX liquidity
- **🛡️ Risk Management**: Sophisticated liquidation system with 80% health factor threshold
- **⚡ Real-time Solvency**: Continuous monitoring and automated liquidation protection
- **🔒 Security First**: Built with Clarity smart contracts ensuring maximum safety
- **📊 Transparent Metrics**: Comprehensive protocol analytics and user position tracking

## System Architecture

### Protocol Components

```
┌─────────────────────────────────────────────────────────────────┐
│                     BitCrown Protocol                           │
├─────────────────────────────────────────────────────────────────┤
│  Liquidity Providers    │    Borrowers     │   Liquidators      │
│  ┌─────────────────┐   │  ┌─────────────┐  │  ┌─────────────┐   │
│  │ Deposit STX     │   │  │ Deposit     │  │  │ Monitor     │   │
│  │ Earn Yield      │   │  │ sBTC        │  │  │ Positions   │   │
│  │ Withdraw Funds  │   │  │ Borrow STX  │  │  │ Execute     │   │
│  └─────────────────┘   │  │ Repay Loan  │  │  │ Liquidation │   │
│                        │  └─────────────┘  │  └─────────────┘   │
├─────────────────────────────────────────────────────────────────┤
│                    Core Smart Contract                          │
│  ┌─────────────────┐   ┌─────────────────┐   ┌─────────────────┐ │
│  │ Position        │   │ Interest Rate   │   │ Liquidation     │ │
│  │ Management      │   │ Calculation     │   │ Engine          │ │
│  └─────────────────┘   └─────────────────┘   └─────────────────┘ │
│  ┌─────────────────┐   ┌─────────────────┐   ┌─────────────────┐ │
│  │ Price Oracle    │   │ Yield           │   │ Risk            │ │
│  │ Integration     │   │ Distribution    │   │ Assessment      │ │
│  └─────────────────┘   └─────────────────┘   └─────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

### Contract Architecture

The BitCrown protocol is implemented as a single, comprehensive Clarity smart contract with the following modules:

#### 1. **Position Management System**

- **Collateral Positions**: Tracks sBTC deposits for each user
- **Lending Positions**: Manages STX deposits with yield snapshots
- **Borrowing Positions**: Monitors STX loans with interest accrual

#### 2. **Interest Rate Engine**

- **Dynamic Rates**: 10% base APR with time-based compounding
- **Yield Distribution**: Automatic interest allocation to liquidity providers
- **Cumulative Indexing**: Precise yield calculation using basis points

#### 3. **Risk Management Framework**

- **Loan-to-Value Ratio**: 70% maximum LTV for borrowing safety
- **Liquidation Threshold**: 80% health factor trigger
- **Automated Liquidation**: Trustless position closure with liquidator rewards

#### 4. **Price Oracle Integration**

- **sBTC/STX Price Feed**: Real-time asset valuation
- **Admin Controls**: Secure price update mechanisms
- **Future Integration**: Ready for Chainlink/Pyth oracle networks

## Data Flow

### Lending Flow

```
STX Holder → deposit-stx() → Protocol Contract → Yield Accrual → withdraw-stx()
```

### Borrowing Flow

```
sBTC Holder → borrow-stx() → Collateral Lock → STX Loan → repay-loan() → Collateral Release
```

### Liquidation Flow

```
Health Monitor → liquidate-position() → Collateral Seizure → Debt Clearing → Liquidator Reward
```

## Protocol Parameters

| Parameter | Value | Description |
|-----------|--------|-------------|
| **Maximum LTV** | 70% | Maximum loan-to-value ratio for borrowing |
| **Liquidation Threshold** | 80% | Health factor below which positions can be liquidated |
| **Base Interest Rate** | 10% APR | Annual borrowing rate for STX loans |
| **Liquidator Reward** | 10% | Bonus paid to liquidators from seized collateral |
| **Yield Precision** | 10,000 basis points | Mathematical precision for yield calculations |

## Smart Contract Functions

### Public Functions

#### Liquidity Provision

- `deposit-stx(amount)` - Deposit STX to earn yields
- `withdraw-stx(amount)` - Withdraw STX deposits plus accrued interest

#### Collateralized Borrowing

- `borrow-stx(collateral-amount, borrow-amount)` - Borrow STX against sBTC collateral
- `repay-loan(repay-amount)` - Repay borrowed STX and unlock collateral

#### Liquidation System

- `liquidate-position(target-user)` - Liquidate undercollateralized positions

#### Administration

- `update-sbtc-price(new-price)` - Update sBTC/STX exchange rate (admin only)
- `pause-protocol()` / `unpause-protocol()` - Emergency controls (admin only)

### Read-Only Functions

#### User Queries

- `get-user-collateral(account)` - Get user's sBTC collateral balance
- `get-user-deposits(account)` - Get user's STX deposit balance
- `get-user-borrows(account)` - Get user's outstanding loan balance
- `get-user-health-factor(account)` - Calculate position health ratio
- `calculate-pending-yield(account)` - Calculate accrued yield for depositor
- `calculate-user-debt(account)` - Calculate total debt including interest

#### Protocol Analytics

- `get-protocol-stats()` - Comprehensive protocol metrics
- `get-sbtc-price-in-stx()` - Current sBTC/STX exchange rate

## Installation & Development

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) v2.0+
- [Node.js](https://nodejs.org/) v18+
- [Git](https://git-scm.com/)

### Setup

```bash
# Clone the repository
git clone https://github.com/ichinedu/bitcrown.git
cd bitcrown

# Install dependencies
npm install

# Check contract syntax
clarinet check

# Run tests
npm test

# Generate test coverage report
npm run test:report
```

### Testing

The protocol includes comprehensive unit tests covering:

- Liquidity provision and withdrawal scenarios
- Collateralized borrowing workflows
- Interest accrual calculations
- Liquidation mechanics
- Edge cases and error conditions

```bash
# Run all tests
npm test

# Watch mode for development
npm run test:watch

# Generate detailed coverage report
npm run test:report
```

## Security Considerations

### Risk Mitigation

1. **Over-collateralization**: 70% LTV ensures loan safety buffer
2. **Liquidation Incentives**: 10% reward encourages timely liquidations
3. **Interest Accrual**: Time-based compound interest prevents debt inflation
4. **Emergency Controls**: Protocol pause functionality for crisis management
5. **Input Validation**: Comprehensive parameter checking and error handling

### Audit Status

⚠️ **Important**: This protocol is currently unaudited. Do not use with real funds on mainnet without a professional security audit.

## Economic Model

### For Liquidity Providers

- Earn yields from borrower interest payments
- Proportional distribution based on deposit size and time
- Withdraw principal plus accrued interest anytime

### For Borrowers

- Access STX liquidity without selling Bitcoin
- Pay 10% APR on borrowed amounts
- Maintain full sBTC ownership throughout loan term

### For Liquidators

- Monitor protocol health factors
- Execute liquidations when positions become unsafe
- Earn 10% reward from liquidated collateral

## Roadmap

- [ ] **Phase 1**: Mainnet deployment and initial liquidity bootstrap
- [ ] **Phase 2**: Integration with decentralized price oracles (Chainlink/Pyth)
- [ ] **Phase 3**: Dynamic interest rate curves based on utilization
- [ ] **Phase 4**: Multi-collateral support (additional Bitcoin derivatives)
- [ ] **Phase 5**: Governance token launch and protocol decentralization

## Contributing

We welcome contributions from the community! Please read our [Contributing Guidelines](CONTRIBUTING.md) and [Code of Conduct](CODE_OF_CONDUCT.md) before submitting pull requests.

### Development Workflow

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
