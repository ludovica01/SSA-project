// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "Taxpayer.sol";


contract TestHardness {
    Taxpayer public t1;
    Taxpayer public t2;


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




}