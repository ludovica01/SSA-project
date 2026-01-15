// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "Taxpayer.sol";


contract TestHardness_Pooling {

    Taxpayer t1;
    Taxpayer t2;

    address public nonContract = address(0x123);    // non-contract address for negative tests

    constructor() {
        t1 = new Taxpayer(address(0), address(0));
        t2 = new Taxpayer(address(0),address(0));
    }


    // INVARIANT: only some valid operations can be performed

    // make t1 marry t2 (only if conditions aree true, otherwise revert)
    function t1_marry_t2() public {
        t1.marry(address(t2));
    }

    /// transfer allowance: only Owner on t1, it is required t1 is married to t2
    function t1_transfer_to_t2(uint amount) public {
        // trasnferAllow will do the try/catch, if fails -> revert
        t1.transferAllowance(amount);
    }




   
    // INVARIANT: if t1 and t2 are married together, the sum of their tax_allowance has to be the same of the INITIAL_TAX_ALLOWANCE
    function echidna_spousal_allowance_sum_preserved() public view returns (bool) {
        // only applicable if both contracts are married each others
        if(!t1.getIsMarried() && !t2.getIsMarried()) {
            return true;        // non applicable
        }
        if(t1.getSpouse() == address(t2) && t2.getSpouse() == address(t1)) {
            uint sumCurrent = t1.getTaxAllowance() + t2.getTaxAllowance();

            uint sumInitial = t1.getInitialTaxAllowance() + t2.getInitialTaxAllowance();

            return sumCurrent == sumInitial;        // must be equal
        }
        return true;            // if are married but not each other, it is not applicable

    }




}
