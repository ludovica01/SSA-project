pragma solidity ^0.8.22;

import "Lottery.sol";

contract Taxpayer {

 uint age; 

 bool isMarried; 

 bool iscontract;

 /* Reference to spouse if person is married, address(0) otherwise */
 address spouse; 


address  parent1; 
address  parent2;

address public  immutable owner;  // since the owner cannot change

 /* Constant default income tax allowance */
 uint constant  DEFAULT_ALLOWANCE = 5000;

 /* Constant income tax allowance for Older Taxpayers over 65 */
  uint constant ALLOWANCE_OAP = 7000;

// the initial value of allowance for this instance is immutable
uint immutable INITIAL_TAX_ALLOWANCE;

 /* Income tax allowance */
 uint tax_allowance; 

 uint income; 

uint256 rev;
bool committed;   // to track if joinLottery has been called

// getter methods
function getIsMarried() public view returns(bool) {
    return isMarried;
}

function getSpouse() public view returns(address) {
    return spouse;
}


function getInitialTaxAllowance() public view returns (uint) {
  return INITIAL_TAX_ALLOWANCE;   // for secure external call
}

function getDefaultAllowance() public view returns (uint) {
  return determineDefaultAllowance();
}

function getAge() public view returns (uint) {
  return age;
}

//setter
function setSpouse(address a) public {
  spouse = a;
}

function setIncome(uint _income) public onlyOwner {
  income = _income;
}


//Parents are taxpayers
 constructor(address p1, address p2) {
   age = 0;
   isMarried = false;
   parent1 = p1;
   parent2 = p2;
   owner = msg.sender;  // immutable assignment
   INITIAL_TAX_ALLOWANCE = DEFAULT_ALLOWANCE;   // immutable assignment for deploy
   spouse = address(0);
   income = 0;
   tax_allowance = INITIAL_TAX_ALLOWANCE;
   iscontract = true;   // cannot change to false during execution
 } 

  // declaration event to notify a marriage
  event Married(address indexed a, address indexed b);





// only the owner is able to perform sensible operations, that i apply it to
 modifier onlyOwner() {
  require(msg.sender == owner, "Only owner");
  _;
 }


 //We require new_spouse != address(0);
 // i need for the marriage to be mutual
 function marry(address new_spouse) public onlyOwner {
  require(!isMarried, "I am already married");
  require(new_spouse != address(0), "Spouse cannot be zero address");
  require(new_spouse != address(this), "Cannot marry myself");
  
  require(new_spouse.code.length > 0, "Spouse must be a contract");   // check the spouse is actually a contract


  // check the spouse is actually a taxpayer contract and is not already married
  bool partnerMarried;
  try Taxpayer(new_spouse).getIsMarried() returns (bool pm) {
    partnerMarried = pm;
  } catch {
    revert("Spouse not compatible");
  }
  require(!partnerMarried, "Spouse already married");

  address oldSpouse = spouse;
  address newSpouseLocal =  new_spouse;
  uint oldTaxAllowance;

  spouse = newSpouseLocal;
  isMarried = true;
  tax_allowance = determineDefaultAllowance();    // update tax allowance based on age
  

  // update the partner variables to guarantee marriage to be mutual
  try Taxpayer(spouse).updateMarriageFromPartner(address(this)) {
    // ok
  } catch {
    // go back if partner update fails
    spouse = oldSpouse;
    isMarried = false;
    tax_allowance = oldTaxAllowance;
    revert("Failed to update partner");
  }

  // try to set partner allowance
  try Taxpayer(newSpouseLocal).setTaxAllowance(Taxpayer(newSpouseLocal).getDefaultAllowance()) {
    // that's ok
  } catch {
    // revert if marriage fails
    spouse = oldSpouse;
    isMarried = false;
    tax_allowance = oldTaxAllowance;
    revert("Failed to set partner allowance");
  }


  emit Married(address(this), newSpouseLocal);

 }
 

  // to mutually update psrtners of a marriage
  function updateMarriageFromPartner(address partner) public {
    require(msg.sender == partner, "Only partner can call this");
    setSpouse(partner);
    isMarried = true;
  }

 
 function divorce() public onlyOwner {

  // to divorce i have to be married in the first place
  require(isMarried, "Not married");
  address oldSpouse = spouse;

  // local changes
  spouse = address(0);
  isMarried = false;

  // reset my allowance to default
  tax_allowance = determineDefaultAllowance();

  // try to remotely update partner, if fails revert it
  if(oldSpouse != address(0) && oldSpouse.code.length > 0) {
    try Taxpayer(oldSpouse).notifyDivorceFromPartner(address(this)) {
      // nothing
    } catch {
      revert("Failed to notify partner");
    }
  }

 }


function notifyDivorceFromPartner(address p) public {
  require(msg.sender == p, "Only partner can notify");
  spouse = address(0);
  isMarried = false;
  
  // reset local allowance
  tax_allowance = determineDefaultAllowance();

}

// lets the partner reset the allowance, if called byits own spouse
function setTaxAllowanceBySpouse(uint ta) public {
  require(msg.sender == spouse, "Only spouse can set");
  tax_allowance = ta;
}



  // Echidna invariant: isMarried has to be coherent and mutual with spouse
  function echidna_marriage_consistency() public view returns(bool) {
    if(spouse == address(0))
      return true;
    
    Taxpayer partner = Taxpayer(spouse);
    return partner.getSpouse() == address(this);
  }


  // if my spouse is not null, then the relationship has to be mututal and partner will set married==true
  function echidna_mutual_marriage_and_flags() public view returns(bool) {
    if(spouse == address(0)) {
      // if i do not have any spouse, i don't have to be married as well
      return !isMarried;
    }
    // but if i do have a spouse:
    if(!isMarried) {
      return false;
    }


    // try to securely read partner. if fails, consider it as violation
    Taxpayer partner = Taxpayer(spouse);
    // partner has to return me as spouse and say they're married
    try partner.getSpouse() returns (address ps) {
      if(ps != address(this)) {
        return false;
      }
    } catch {
      return false;
    }

    try partner.getIsMarried() returns (bool pm) {
      if(!pm) {
        return false;
      }
    } catch {
      return false;
    }

    return true;
  }

  // invariant: i cannot be married with myself
  function echidna_not_self_spouse() public view returns (bool) {
    return spouse != address(this);
  }

  // invariant to not let taxable income to be negative
  function echidna_taxable_non_negative() public view returns (bool) {
    return taxableIncome() >= 0;    // always true for uint
  }

  function echidna_no_tax_below_allowance() public view returns (bool) {
    if(income <= tax_allowance) {
      return calculateTax(200) == 0;    // 200 because is for 1
    }
    return true;
  }

  
  // invariant: the flag iscontract cannot change to false during the execution of the contract
  function echidna_iscontract_is_true() public view returns (bool) {
    return iscontract;
  }

  // invariant: if tax payer is single, tax_allowance = value only based on age
  function echidna_age_allowance_base_consistency_single() public view returns (bool) {
    if(spouse != address(0) || isMarried) {
      return true;    // not applicable if married
    }
    return tax_allowance == determineDefaultAllowance();
  }

  // invvariant: to handle thhe sum of pooling for married tax payers
  function echidna_spousal_allowance_sum_constant() public view returns (bool) {

    if(!isMarried || spouse == address(0)) {
      return true;    // not applicable
    }

    uint myCurrent = tax_allowance;
    Taxpayer partner = Taxpayer(spouse);

    uint partnerCurrent;
    uint partnerInitial;
    uint partnerBase;

    // reads the current allowance of partner
    try partner.getTaxAllowance() returns (uint pc) {
      partnerCurrent = pc;
    } catch {
      return false;   // if not accessible it is a violation
    }

    // read the initial tax allowance of partner
    try partner.getInitialTaxAllowance() returns (uint pi) {
      partnerInitial = pi;
    } catch {
      return false;
    }

    // reads the partner allowance based on its age (OAP or default)
    try partner.getDefaultAllowance() returns (uint pb) {
      partnerBase = pb;
    } catch {
      return false;
    }

    uint myBase = determineDefaultAllowance();

    // combined check: current sum = initial sum, and current sum <= maximumbase sum
    bool checkInitial = (myCurrent + partnerCurrent) == (INITIAL_TAX_ALLOWANCE + partnerInitial);
    bool checkOAP = (myCurrent + partnerCurrent) <= (myBase + partnerBase);

    return checkInitial && checkOAP;

  }

  // invariant: coherence between reeveal and commit
  function echidna_commit_consistency(address lot) public view returns (bool) {
    // if no reveal is stored, invariant is respected
    if(rev == 0) {
      return true;
    }

    // check if lot is a contract
    if(lot == address(0) || lot.code.length == 0) {
      return true;    // cannot check
    }

    try Lottery(lot).commits(address(this)) returns (bytes32 c) {
      return c == keccak256(abi.encode(rev));
    } catch {
      return false;   // if it fails to read, we consider the invariant as violated
    }

  }

  // structurral invariant: rev has to be resetted after revealLottery
  function echidna_rev_reset_after_reveal() public view returns(bool) {
    // if there is a commit, rev has to  be 0 ONLY after revealLottery
    if(committed) {
      return rev != 0;
    } else {
      return rev == 0;    // if there is no commit, rev = 0
    }
  }



 /* Transfer part of tax allowance to own spouse */
 function transferAllowance(uint change) public onlyOwner {
  
  require(spouse != address(0), "No spouse");
  require(change > 0, "Zero change");
  require(change <= tax_allowance, "Not enough allowance");

  tax_allowance -= change;

  // i try -> secure way
  try Taxpayer(spouse).receiveAllowance(change, address(this)) {
    // that's okay
  } catch {
    revert("Failed to transfer spouse");
  }
 }


 function receiveAllowance(uint amount, address from) public {
  require(msg.sender == spouse || msg.sender == from, "Only spouse or origin");
  tax_allowance += amount;
 }

  // need to handle the case if tax payer is older than 65
 function haveBirthday() public onlyOwner {
  age++;
  if(!isMarried && spouse == address(0)) {  // only if single
        if(age >= 65) {
            tax_allowance = ALLOWANCE_OAP;
        } else {
            tax_allowance = DEFAULT_ALLOWANCE;
        }
    }
 }
 
  function setTaxAllowance(uint ta) public {
    require(msg.sender == owner || msg.sender == spouse || isAuthorizedContract(msg.sender), "Not authorized to set allowance");
  }

  // check if the Taxpayer is actually a contract and if it has the authorization
  function isAuthorizedContract(address a) internal view returns (bool) {
    if(a.code.length == 0) {
      return false;
    }

    try Lottery(a).isContract() returns (bool ok) {
      return ok;
    } catch {
      return false;
    }

  }
  




  function determineDefaultAllowance() internal view returns (uint) {
    if(age >= 65) {
      return ALLOWANCE_OAP;
    }
    return DEFAULT_ALLOWANCE;
  }


  function getTaxAllowance() public view returns(uint) {
    return tax_allowance;
  }


  function isContract() public view returns(bool){
    return iscontract;
  }



  function joinLottery(address lot, uint256 r) public onlyOwner {
    require(lot != address(0) && lot.code.length > 0 , "Invalid lottery");    // to avoid function failure

    try Lottery(lot).commit(keccak256(abi.encode(r))) {   // try-catch to avoid failure
      rev = r;
      committed = true;   // there is an active commit
    } catch {
      revert("Lottery commit failed");
    }
  }


   function revealLottery(address lot, uint256 r) public onlyOwner {
    require(lot != address(0), "Invalid lotterry");
    require(rev != 0, "No committed reveal");

    try Lottery(lot).reveal(r) {
      rev = 0;
      committed = false;    // reset the flag
    } catch {
      revert("Lottery reveal failed");
    }
  }





  // to get the taxable income (so only the part over the allowance)
  function taxableIncome() public view returns(uint) {
    if(income <= tax_allowance) {
      return 0;
    }

    return income - tax_allowance;
  }


  // to compute the tax
  function calculateTax(uint value) public view returns (uint) {
    uint t = taxableIncome();
    return (t * value) / 1000;
  }




}
