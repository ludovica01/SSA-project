Security Analysis and Property-Based Fuzzing of Fiscal and Lottery Smart Contracts using Echidna

This repository contains a security-focused implementation of a decentralized fiscal and lottery system. The project utilizes Echidna for property-based fuzzing to ensure the integrity of taxpayer logic, spousal allowance pooling, and the fairness of a commit-reveal lottery system.
Project Overview
The system is designed around two core components:
1. Taxpayer Management: Handles personal data (age, income), marriage/divorce status, and tax allowance calculations. It includes a unique feature allowing married couples to pool and transfer their tax allowances.
2. Commit-Reveal Lottery: A lottery system where winners are selected based on revealed secrets, granting them a maximum tax allowance of 9000.

Smart Contract Architecture

Taxpayer.sol
• Allowances: Standard allowance is set at 5000 (DEFAULT_ALLOWANCE), increasing to 9000 (ALLOWANCE_OAP) for taxpayers aged 65 or older.
• Marriage Logic: Implements mutual verification. For a marriage to be valid, both contracts must point to each other as spouses.
• Allowance Pooling: Spouses can use transferAllowance to shift tax benefits between one another.
• Tax Calculation: Taxes are calculated based on taxableIncome, which is the portion of income exceeding the current allowance.

Lottery.sol
• Phases: Includes startLottery, commit, reveal, and endLottery phases.
• Fairness: Uses a commit-reveal scheme to prevent participants from choosing their values after seeing others'.
• Winner Selection: The winner is chosen deterministically using the modulo of the sum of all revealed values.

Security Properties (Invariants)
The project uses several TestHardness contracts to define invariants that Echidna must verify:
1. Fiscal Invariants
• Negative Taxable Income: The system must ensure taxableIncome never results in an underflow or negative value.
• Tax Coherence: No tax should be calculated if the income is below or equal to the allowance.
• Age Consistency: Taxpayers under 65 must have the default allowance unless they are married or won the lottery.
2. Spousal & Pooling Invariants
• Marriage Mutuality: If Taxpayer A is married to Taxpayer B, Taxpayer B must be married to Taxpayer A.
• No Self-Marriage: A taxpayer cannot marry themselves.
• Conservation of Allowance: During an allowance transfer between spouses, the total sum of their allowances must remain constant.
3. Lottery Invariants
• Age Restriction: Participants aged 65 or older are strictly rejected from joining the lottery.
• Unique Participation: A single address cannot appear more than once in the revealed participants list for a single round.
• Commit-Reveal Consistency: The revealed value must match the hashed commitment stored in the lottery contract.
• State Reset: After the reveal phase, the taxpayer's internal commitment flags must be correctly reset to prevent re-revealing.

Negative Testing & Robustness
The test suite includes an Attacker contract and specific failure tests to verify that:
• Unauthorized users cannot call onlyOwner functions like setIncome or startLottery.
• Allowance transfers fail if the parties are not married or if the amount exceeds the available allowance.
• Lottery commits fail if the lottery has not yet started.

How to Run the Fuzzer
To run the property-based tests, ensure you have Echidna installed and execute the following commands:
# Example for testing the Lottery logic
echidna-test . --contract TestHardness_Lottery --config config.yaml

# Example for testing Fiscal and Pooling logic
echidna-test . --contract TestHardness_Pooling --config config.yaml

--------------------------------------------------------------------------------
Disclaimer: This project is part of a security analysis study and is intended for educational purposes regarding smart contract verification.
