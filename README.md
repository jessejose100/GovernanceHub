# GovernanceHub

A decentralized autonomous organization (DAO) governance smart contract enabling members to join, create proposals, vote (including delegated voting), and execute approved proposals. Built for transparent, democratic treasury management and decision-making on the Stacks blockchain.

---

## Features

- **Membership Management**: Users join the DAO by contributing STX tokens to the treasury.
- **Proposal Lifecycle**: Members can create proposals specifying title, description, action, requested funds, and recipient.
- **Voting System**: Members vote yes/no on proposals within a defined voting period.
- **Delegated Voting**: Members can delegate their voting power to other members to vote on their behalf.
- **Proposal Execution**: Approved proposals can be executed, transferring funds from the treasury to the specified recipient.
- **Governance Parameters**: Configurable vote threshold (default 51%) and voting period (~1 day in blocks).
- **Treasury Management**: Tracks the treasury balance and ensures sufficient funds before proposal execution.

---

## Usage

### Join the DAO

Contribute STX tokens to become a member and fund the treasury.

```clarity
(join-dao contribution)
```

- `contribution` (uint): Amount of STX to contribute (must be > 0).

### Create a Proposal

Submit a new proposal for DAO members to vote on.

```clarity
(create-proposal title description action amount recipient)
```

- `title` (string-ascii 100): Short title of the proposal.
- `description` (string-utf8 500): Detailed description.
- `action` (string-utf8 200): Description of the action to be taken.
- `amount` (uint): STX amount requested from treasury.
- `recipient` (principal): Address to receive funds if approved.

### Vote on a Proposal

Cast a yes/no vote on an active proposal.

```clarity
(vote-on-proposal proposal-id vote)
```

- `proposal-id` (uint): ID of the proposal.
- `vote` (bool): `true` for yes, `false` for no.

### Delegate Voting Power

Delegate your voting power to another member.

```clarity
(delegate-vote delegate)
```

- `delegate` (principal): Member to delegate your vote to.

### Vote With Delegation

Vote on a proposal with your own vote plus delegated votes.

```clarity
(vote-with-delegation proposal-id vote)
```

- `proposal-id` (uint): Proposal ID.
- `vote` (bool): `true` or `false`.

### Execute Proposal

Execute an approved proposal to transfer funds and finalize the action.

```clarity
(execute-proposal proposal-id)
```

- `proposal-id` (uint): Proposal to execute.

---

## Governance Parameters

- **Vote Threshold**: Minimum yes-vote percentage for approval (default 51%).
- **Voting Period**: Duration proposals remain open for voting (~144 blocks, approx. 1 day).
- **Treasury Balance**: Tracks total STX available for proposals.

---

## Error Codes

- `ERR_UNAUTHORIZED (u100)`: Unauthorized action.
- `ERR_ALREADY_MEMBER (u101)`: Caller is already a member.
- `ERR_NOT_MEMBER (u102)`: Caller is not a member.
- `ERR_PROPOSAL_NOT_FOUND (u103)`: Proposal does not exist.
- `ERR_ALREADY_VOTED (u104)`: Member has already voted on this proposal.
- `ERR_VOTING_CLOSED (u105)`: Voting period has ended.
- `ERR_PROPOSAL_NOT_APPROVED (u106)`: Proposal not approved.
- `ERR_INSUFFICIENT_FUNDS (u107)`: Insufficient treasury funds.
- `ERR_INVALID_PROPOSAL (u108)`: Invalid proposal parameters.
- `ERR_SELF_DELEGATION (u109)`: Cannot delegate vote to self.
- `ERR_NO_DELEGATION (u110)`: No delegation found.

---

## Contribution

Contributions are welcome! To contribute:

- Fork the repository.
- Create a feature branch.
- Submit pull requests with clear descriptions.
- Report issues or suggest improvements via GitHub Issues.

Please adhere to the existing code style and include tests for new features.

---

## License

This project is licensed under the MIT License. See the LICENSE file for details.

---

## Related Projects

- [Stacks Blockchain](https://www.stacks.co) — Blockchain platform supporting Clarity smart contracts.
- [Clarity Language](https://docs.stacks.co/docs/clarity) — Smart contract language used.
- [DAO Frameworks](https://github.com/daostack) — Examples of DAO governance systems.

---

This contract provides a robust foundation for decentralized governance with flexible voting and treasury management, empowering communities to self-govern transparently and efficiently.
