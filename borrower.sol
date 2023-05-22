// SPDX-License-Identifier : MIT

 pragma solidity 0.8.20;

  contract CrowdBank {

    address public owner;

    enum ProposalState {
        Waiting,
        Accepted,
        Paid
    }

    struct Proposal {
        address payable lender;
        uint loanId;
        ProposalState state;
        uint rate;
        uint amount;
    }

    Proposal[] public proposalList;

    enum LoanState {
        Accepting,
        Locked,
        Successful,
        Failed
    }

    struct Loan {
        address borrower;
        LoanState state;
        uint dueDate;
        uint amount;
        uint proposalCount;
        uint collected;
        uint startDate;
        bytes32 mortgage;
        mapping (uint => uint) proposal;
    }

    Loan[] public loanList;

// create the mappings

    mapping (address => uint[]) public loanMap;
    mapping (address => uint[]) public lendMap;

    constructor () public {
        owner = msg.sender;
    }

    function hasActiveLoan(address borrower) public view returns (bool) {

        // so we will simply use the var validLoans to reference loanMap[borrower].length
        uint validLoans = loanMap[borrower].length;

        if(validLoans == 0) return false;
        Loan storage obj = loanList[loanMap[borrower][validLoans - 1]];
        
        if(loanList[validLoans - 1].state == LoanState.Accepting) return true;
        if(loanList[validLoans - 1].state == LoanState.Locked) return true;
        
        // the boolean value that the function should return will remain unassigned if you do not include "return false"
        return false;
    }

    function newLoan(uint dueDate, uint amount, bytes32 mortgage) public {

        if(hasActiveLoan(msg.sender)) return;
        uint currentDate = block.timestamp;

        loanList.push(Loan(msg.sender, LoanState.Accepting, dueDate, amount, 0, 0, currentDate, mortgage));
        loanMap[msg.sender].push(loanList.length - 1);
    }

    function newProposal(uint loanId, uint rate) public payable {
        if(loanList[loanId].borrower == address(0) || loanList[loanId].state != LoanState.Accepting)
        return;   

        proposalList.push(Proposal(msg.sender, loanId, ProposalState.Waiting, rate, msg.value));
        lendMap[msg.sender].push(proposalList.length -1);

        loanList[loanId].proposalCount++;
        loanList[loanId].proposal[loanList[loanId].proposalCount - 1] = proposalList.length - 1;
    }

    function lockLoanStateToPayBorrower(uint loanId) public {
        if(loanList[loanId].state == LoanState.Accepting) {
            loanList[loanId].state = LoanState.Locked;

            for(uint i = 0; i < loanList[loanId].proposalCount; i++) {

              uint numI = loanList[loanId].proposal[i];

            if(proposalList[numI].state == ProposalState.Accepted) {
              
              msg.sender.transfer(proposalList[numI].amount); // send this to whoever wants to borrow
            }


            }
        }
    }


    }

    function getTotalProposalsByLender(address lender) public view returns (uint) {
        return lendMap[lender].length;
    }

    // functions for the borrower

    function knowLoanStatus(address borrowers) public view returns (LoanState) {
        uint loanLength = loanMap[borrowers].length;

        if(loanLength == 0) {
            return LoanState.Successful;
        }

        return loanList[loanMap[borrowers][loanLength -1].state];
    }

    function getLastLoanDetails(address borrower) public view returns (LoanState, uint, uint, uint) {
        uint loanLength = loanMap[borrower].length;
        Loan storage obj = loanList[loanMap[borrower][loanLength -1]];
        return (obj.state, obj.dueDate, obj.amount, obj.proposalCount, obj.collected);
    }

    function getDetailsByIdPosition(uint loanId, uint numI) public view returns (ProposalState, uint, uint, uint, address) {
        
        Proposal storage obj = proposalList[loanList[loanId].proposal[numI]];

        return (obj.state, obj.rate, obj.amount, loanList[loanId].proposal[numI], obj.lender);
    }

    function totalBorrowedLoan(address borrower) public view returns (uint) {
        loanMap[borrower].length;
    }

    function numTotalLoans() public view returns (uint) {
     return loanList.length;
    }
    
}

