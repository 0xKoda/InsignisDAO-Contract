// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 _______________________1¶¶¶_______________________
________________________¶¶¶_______________________
________________________¶¶¶_______________________
___________¶1___¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶1___¶¶__________
_________¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶________
_________¶¶¶¶¶¶¶¶______¶¶¶¶1_____1¶¶¶¶¶¶¶1________
__________¶¶¶___________¶¶¶___________¶¶¶_________
__________¶¶¶___________¶¶¶___________¶¶¶_________
________¶¶¶¶¶¶__________¶¶¶__________¶¶¶¶¶________
________¶¶¶¶¶¶__________¶¶¶__________¶¶¶¶¶________
________¶__¶_¶__________¶¶¶_________1¶_¶_¶1_______
_______1¶_¶¶_¶¶_________¶¶¶_________¶1_¶_1¶_______
_______¶¶_1¶__¶_________¶¶¶________¶¶__¶__¶¶______
______¶¶__1¶__¶¶________¶¶¶________¶___¶___¶______
______¶___¶¶___¶1_______¶¶¶_______¶¶___¶___¶¶_____
_____¶¶___¶¶___1¶_______¶¶¶______1¶____¶____¶1____
____1¶____¶¶____¶¶______¶¶¶______¶1____¶____1¶____
____¶1____¶¶_____¶______¶¶¶_____¶¶_____¶_____¶¶___
___¶¶_____¶¶_____¶¶_____¶¶¶_____¶______¶______¶___
___¶______¶¶______¶¶____¶¶¶____¶¶______¶______¶¶__
__¶________¶_______¶____¶¶¶____¶_______¶_______¶__
¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶__¶¶¶_1¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶
¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶1_¶¶¶_¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶
_¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶___¶¶¶__1¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶
___¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶_____¶¶¶_____¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶1__
______1¶¶¶¶¶¶¶¶1___1¶¶¶¶¶¶¶¶¶¶¶____¶¶¶¶¶¶¶¶¶______
________________¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶_______________
_______________¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶_______________
________________¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶_______________

InsignisDAO is a smart contract for propsing, voting, and funding charitable smart contracts.
*/

contract InsignisDAO is ReentrancyGuard, AccessControl {
    bytes32 public constant CONTRIBUTOR_ROLE = keccak256("CONTRIBUTOR"); //Define roles of CONTRIBUTOR
    bytes32 public constant STAKEHOLDER_ROLE = keccak256("STAKEHOLDER"); // Define role of STAKEHOLDER
    uint32 constant minimumVotingPeriod = 1 weeks; //minimumVotingPeriod Is set here to 1 week
    uint256 numOfProposals;
    
    struct CharityProposal { //Struct holding the relevant data for CharityProposal
        uint256 id; 
        uint256 amount; 
        uint256 livePeriod;
        uint256 votesFor;
        uint256 votesAgainst;
        string description;
        bool votingPassed;
        bool paid;
        address payable charityAddress;
        address proposer;
        address paidBy;
    }
     
    mapping(uint256 => CharityProposal) private charityProposals; //Mapping a uint256 key to CharityProposal as the value
    mapping(address => uint256[]) private stakeholderVotes; // Mapping stakeholder address to a list of addresses the stakeholder has voted on
    mapping(address => uint256) private contributors; // Mapping contributor addresses and the amounts they have sent to the InsignisDAO
    mapping(address => uint256) private stakeholders; //Mapping of addresses and balances of stakeholders
    
    //emits event for each new propsal
    event ContributionReceived(address indexed fromAddress, uint256 amount);
    event NewCharityProposal(address indexed proposer, uint256 amount);
    event PaymentTransfered(
        address indexed stakeholder,
        address indexed charityAddress,
        uint256 amount
    );

    modifier onlyStakeholder(string memory message) { //sets AccessControl
        require(hasRole(STAKEHOLDER_ROLE, msg.sender), message);
        _;
    }

    modifier onlyContributor(string memory message) { //sets AccessControl
        require(hasRole(CONTRIBUTOR_ROLE, msg.sender), message);
        _;
    }
    
/* Creates a new proposal
 * @param description set as calldata for gas efficiency
 * @param address for funding if proposal succeeds
 * @param funding amount
 */
    function createProposal( 
        string calldata description,
        address charityAddress,
        uint256 amount
    )
        external
        onlyStakeholder("Only stakeholders are allowed to create proposals")
    {
        uint256 proposalId = numOfProposals++;
        CharityProposal storage proposal = charityProposals[proposalId];
        proposal.id = proposalId;
        proposal.proposer = payable(msg.sender);
        proposal.description = description;
        proposal.charityAddress = payable(charityAddress);
        proposal.amount = amount;
        proposal.livePeriod = block.timestamp + minimumVotingPeriod;

        emit NewCharityProposal(msg.sender, amount);
    }
    
/* vote is an external function allowing votes on proposals when called.
 * @param proposalId number
 * @param bool for vote sway
 */
    function vote(uint256 proposalId, bool supportProposal)
        external
        onlyStakeholder("Only stakeholders are allowed to vote")
    {
        CharityProposal storage charityProposal = charityProposals[proposalId];

        votable(charityProposal);

        if (supportProposal) charityProposal.votesFor++;
        else charityProposal.votesAgainst++;

        stakeholderVotes[msg.sender].push(charityProposal.id);
    }
    
/* votable is called in the vote function, verifies if an account can be voted on
 * @param targets CharityProposal in storage
 */
    function votable(CharityProposal storage charityProposal) private {
        if (
            charityProposal.votingPassed ||
            charityProposal.livePeriod <= block.timestamp
        ) {
            charityProposal.votingPassed = true;
            revert("Voting period has passed on this proposal");
        }

        uint256[] memory tempVotes = stakeholderVotes[msg.sender];
        for (uint256 votes = 0; votes < tempVotes.length; votes++) {
            if (charityProposal.id == tempVotes[votes])
                revert("This stakeholder already voted on this proposal");
        }
    }
    
/*handles payment to specified address after propsal has ended.
 * @param Takes proposalId from mapping
 **/
    function payCharity(uint256 proposalId)
        external
        onlyStakeholder("Only stakeholders are allowed to make payments")
    {
        CharityProposal storage charityProposal = charityProposals[proposalId];

        if (charityProposal.paid)
            revert("Payment has been made to this charity");

        if (charityProposal.votesFor <= charityProposal.votesAgainst)
            revert(
                "The proposal does not have the required amount of votes to pass"
            );

        charityProposal.paid = true;
        charityProposal.paidBy = msg.sender;

        emit PaymentTransfered(
            msg.sender,
            charityProposal.charityAddress,
            charityProposal.amount
        );

        return charityProposal.charityAddress.transfer(charityProposal.amount);
    }

    receive() external payable {
        emit ContributionReceived(msg.sender, msg.value);
    }
    
/* function to award stakeholder role.
 * @param checks amount sent to contract meets requirement.
 **/
    function makeStakeholder(uint256 amount) external {
        address account = msg.sender;
        uint256 amountContributed = amount;
        if (!hasRole(STAKEHOLDER_ROLE, account)) {
            uint256 totalContributed =
                contributors[account] + amountContributed;
            if (totalContributed >= 5 ether) {
                stakeholders[account] = totalContributed;
                contributors[account] += amountContributed;
                _setupRole(STAKEHOLDER_ROLE, account);
                _setupRole(CONTRIBUTOR_ROLE, account);
            } else {
                contributors[account] += amountContributed;
                _setupRole(CONTRIBUTOR_ROLE, account);
            }
        } else {
            contributors[account] += amountContributed;
            stakeholders[account] += amountContributed;
        }
    }
    
//reterns a list of all proposals
    function getProposals()
        public
        view
        returns (CharityProposal[] memory props)
    {
        props = new CharityProposal[](numOfProposals);

        for (uint256 index = 0; index < numOfProposals; index++) {
            props[index] = charityProposals[index];
        }
    }
//gets proposals by proposalId
    function getProposal(uint256 proposalId)
        public
        view
        returns (CharityProposal memory)
    {
        return charityProposals[proposalId];
    }
//returns a list of proposals the stakeholder has voted on
    function getStakeholderVotes()
        public
        view
        onlyStakeholder("User is not a stakeholder")
        returns (uint256[] memory)
    {
        return stakeholderVotes[msg.sender];
    }
//returns stakeholders total contribution to the InsignisDAO
    function getStakeholderBalance()
        public
        view
        onlyStakeholder("User is not a stakeholder")
        returns (uint256)
    {
        return stakeholders[msg.sender];
    }
//checks if caller is stakeholder
    function isStakeholder() public view returns (bool) {
        return stakeholders[msg.sender] > 0;
    }
//returns total balance of contributor
    function getContributorBalance()
        public
        view
        onlyContributor("User is not a contributor")
        returns (uint256)
    {
        return contributors[msg.sender];
    }
//checks if caller is contributor
    function isContributor() public view returns (bool) {
        return contributors[msg.sender] > 0;
    }
}
