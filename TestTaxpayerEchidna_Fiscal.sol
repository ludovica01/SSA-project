// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "Taxpayer.sol";


contract TestHardness_Fiscal {

    Taxpayer public t1;
    
    constructor() {
        t1 = new Taxpayer(address(0), address(0));
    }


    // function to simulate the birthday (owner only)
    function t1_haveBirthday() public {
        t1.haveBirthday();      // only owner can call it, here echidna will use deployer as owner
    }

    // function to set the income
    // function t1_setIncome(uint _income) public {
        // t1.setIncome(_income);
    // }



    // INVARIANTS: for fiscal logic

    // age can only be >= 0
    function echidna_age_non_negative() public view returns(bool) {
        return t1.getAge() >= 0;
    }


    // tax allowance only has to chage if singlle and makes 65
    function echidna_tax_allowance_oap_if_single_over_65() public view returns (bool) {
        uint allowance = t1.getTaxAllowance();
        uint age = t1.getAge();

        if(!t1.getIsMarried()) {
            if(age>= 65) {
                return allowance == 7000;       // for over 65
            } else {
                return allowance == 5000;       // the default one
            }
        }
        // if married allowance won't change during birthdays
        return true;
    }

    // the taxable income cannot be negative
   function echidna_taxable_consistent() public view returns (bool) {
    uint income = t1.getIncome();
    uint allowance = t1.getTaxAllowance();
    uint taxable = t1.taxableIncome();

    if (income >= allowance) {
        return taxable == income - allowance;
    } else {
        return taxable == 0;
    }
}


    // check if the income is less than tax_allowance, and if the calculated tax is 0
    function echidna_no_tax_below_allowance() public view returns (bool) {
        uint income = t1.getIncome();
        uint allowance = t1.getTaxAllowance();

        if(income <= allowance)  {
            return t1.calculateTax(200) == 0;
        }
        return true;
    }

    // check if tax is coherent with taxableIncome
    function echidna_tax_consistency() public view returns (bool) {
        uint t = t1.taxableIncome();
        uint tax = t1.calculateTax(100);        // 10%

        return tax == (t*100)/1000;     // for the percentage
    }






}
