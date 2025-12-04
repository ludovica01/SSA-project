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



    // negative actions: fails are expected

    // attempt to transfer wheen not married -> has to revert
    function fail_transfer_when_not_married(uint married) public {
        // ensure t1 isn't married
        t1.transferAllowance(0);
    }   

    // attempt to transfer 0. shouldn't be possible
    function fail_transfer_zero_amount() public {
        t1.transferAllowance(0);
    }

    // attempt to transfer more than its allowance. should revert
    function fail_tramsfer_exceeded_allowance(uint amount) public {
        t1.transferAllowance(amount);
    }

    // attempt to call receiveAllowance from a non-spouse/non from caller. should revert
    function fail_unauthorized_receive(uint amount) public {
        t1.receiveAllowance(amount, address(this));        // since msg.sender != from
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



    // INVARIANT: if t1 transferred allowance to t2, then the received value has to  be visible as add in tax_allowance of t2
    // the sum should not increase more than the maximum base
    function echidna_allowance_sum_leq_base() public view returns (bool) {
        // if marriied, the current sum should be less/equal than the sum of deffault/OAP for the two of them
        if(t1.getIsMarried() && t2.getIsMarried() &&
            t1.getSpouse() == address(t2) && t2.getSpouse() == address(t1)) {

                uint myBase = t1.getDefaultAllowance();
                uint partnerBase = t2.getDefaultAllowance();
                uint sumCurrent = t1.getTaxAllowance() + t2.getTaxAllowance();

                return sumCurrent <= (myBase + partnerBase);
            }
        return true;        // not applicable if not married
    }


    // there should not be unwanted modifies o allowance values by non autthorized callers
    function echidna_allowance_non_negative() public view returns (bool) {
        return t1.getTaxAllowance() >= 0 && t1.getTaxAllowance() >= 0;
    }


    // receiving coherence: if t2 has recently received by t1, then itss currentt tax allowance value will be
    // higher than the initial one
    function echidna_received_at_least_initial() public view returns (bool) {
        return t2.getTaxAllowance() >= t2.getInitialTaxAllowance();
    }







}