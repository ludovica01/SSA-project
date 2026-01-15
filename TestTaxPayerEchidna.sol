// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "Taxpayer.sol";


contract TestHardness {
    Taxpayer public t1;
    Taxpayer public t2;
    address nonContract = address(0x123);


    // constructor: create 2 Taxpayer with whatever addresses parent: address(0) is ok
    constructor() {
        t1 = new Taxpayer(address(0), address(0));
        t2 = new Taxpayer(address(0), address(0));
    }

    // make marry t2 with t1 (using its address)
    function t2_marry_t1()public {
        t2.marry(address(t1));
    }
    // for divorce
    function t2_divorce() public {
        t2.divorce();
    }


    // attempt to marry with null address
    function fail_marry_with_zero_address() public {
        t2.marry(address(0));
    }

    // attempt to marry with a non contract-address
    function fail_marry_with_non_contract() public {
        t2.marry(nonContract);
    }

    // attempt to marry an already married contract
    function fail_marry_with_already_married() public {
        Taxpayer tmp = new Taxpayer(address(0), address(0));
        t1.marry(address(tmp));
        t2.marry(address(t1));      // should revert the action
    }

    // ECHIDNA INVARIANT: if t1 is married, then its spouse has to point to t2
    // and if t2 is also married, its spouse has to point to t1
    // if they are not married, the condition is true as well
    function echidna_mutual_marriage() public view returns (bool) {
        // if t1 is married then its spouse address has to be t2's
        if(t1.getIsMarried()) {
            if(t1.getSpouse() != address(t2)) {
                return false;
            }
        }

        // if t2 is married then its spouse address has to be t1's
        if(t2.getIsMarried()) {
            if(t2.getSpouse() != address(t1)) {
                return false;
            }
        }

        return true;

    }


// INVARIANT: cannot marry myself
function echidna_not_self_spouse() public view returns (bool) {
    return t1.getSpouse() != address(t1) && t2.getSpouse() != address(t2);
}


// INVARIANT: divorce revert a coherent state
function echidna_divorce_coherence() public view returns (bool) {
    if(!t1.getIsMarried() && !t2.getIsMarried()) {
        return t1.getSpouse() == address(0) && t2.getSpouse() == address(0);
    }
    return true;
}




}
