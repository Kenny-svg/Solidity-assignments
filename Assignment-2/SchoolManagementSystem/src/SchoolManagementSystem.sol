// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;


interface ERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}
contract SchoolManagementSystem {
    address public owner;

      modifier onlyOwner() {
        require(msg.sender == owner, "NOT_OWNER");
        _;
    }

    event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);

      uint256 private locked = 1;
    modifier nonReentrant() {
        require(locked == 1, "REENTRANCY");
        locked = 2;
        _;
        locked = 1;
    }

    enum FeePaymentStatus {
        Paid,
        Unpaid
    }
        ERC20 public paymentToken;
    
     struct Student {
        address id;               
        string name;               
        uint256 age;               
        uint16 level;           
        FeePaymentStatus status;   
        uint256 lastPaymentTime;   
        uint256 totalPaid;         
        uint256 registeredAt;     
        bool isRegistered;         
    }



    struct Staff {
        address id;               
        string name;               
        string role;               
        uint256 salaryAmount;      
        bool isActive;             
        uint256 lastPaidAt;        
        bool isRegistered;         
    }

    mapping(address => Student) public students;
    mapping(address => Staff) public staffs;

    address[] private studentIndex;
    address[] private staffIndex;

    mapping(uint16 => uint256) public feeByLevel;

    event FeeSet(uint16 indexed level, uint256 amount);
    event StudentRegistered(
        address indexed student,
        uint16 indexed level,
        uint256 feePaid,
        uint256 timestamp
    );

    event StudentPaymentStatusUpdated(
        address indexed student,
        FeePaymentStatus status,
        uint256 timestamp
    );

    event StaffRegistered(
        address indexed staff,
        uint256 salaryAmount,
        bool isActive,
        uint256 timestamp
    );

    event StaffPaid(
        address indexed staff,
        uint256 salaryAmount,
        uint256 timestamp
    );


    event TreasuryTokenWithdrawn(address indexed to, uint256 amount);
    event TreasuryEtherWithdrawn(address indexed to, uint256 amount);

     constructor(address tokenAddress) {
        require(tokenAddress != address(0), "TOKEN_ZERO");
        owner = msg.sender;
        paymentToken = ERC20(tokenAddress);
        emit OwnershipTransferred(address(0), msg.sender);
    }
  function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "OWNER_ZERO");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function setFee(uint16 level, uint256 amount) external onlyOwner {
        require(_isValidLevel(level), "INVALID_LEVEL");
        require(amount > 0, "AMOUNT_ZERO");
        feeByLevel[level] = amount;
        emit FeeSet(level, amount);
    }

    function registerStudent(
        string calldata name,
        uint256 age,
        uint16 level
    ) external nonReentrant {
        // Prevent registering twice
        require(!students[msg.sender].isRegistered, "ALREADY_REGISTERED");

        // Validate level is only 100/200/300/400
        require(_isValidLevel(level), "INVALID_LEVEL");

        // Get fee for that level
        uint256 fee = feeByLevel[level];
        require(fee > 0, "FEE_NOT_SET");

        // Collect fee in ERC-20: student -> contract
        _safeTransferFrom(address(paymentToken), msg.sender, address(this), fee);

        // Save student record (contract controls status + timestamp)
        students[msg.sender] = Student({
            id: msg.sender,
            name: name,
            age: age,
            level: level,
            status: FeePaymentStatus.Paid,
            lastPaymentTime: block.timestamp,
            totalPaid: fee,
            registeredAt: block.timestamp,
            isRegistered: true
        });

        // Add student address to the list for "get all students"
        studentIndex.push(msg.sender);

        // Log a blockchain receipt
        emit StudentRegistered(msg.sender, level, fee, block.timestamp);
    }


     function getStudent(address student) external view returns (Student memory) {
        return students[student];
    }

function updateStudentPaymentStatus(address student, FeePaymentStatus status) external onlyOwner {
        require(students[student].isRegistered, "STUDENT_NOT_FOUND");
        students[student].status = status;
        students[student].lastPaymentTime = block.timestamp;
        emit StudentPaymentStatusUpdated(student, status, block.timestamp);
    }
   function listStudents(uint256 start, uint256 count) external view returns (address[] memory) {
        uint256 total = studentIndex.length;
        if (start >= total) return new address[](0);

        uint256 end = start + count;
        if (end > total) end = total;

        address[] memory result = new address[](end - start);
        for (uint256 i = start; i < end; i++) {
            result[i - start] = studentIndex[i];
        }
        return result;
    }
      // Total number of students registered
    function totalStudents() external view returns (uint256) {
        return studentIndex.length;
    }

     function registerStaff(
        address staffAddr,
        string calldata name,
        string calldata role,
        uint256 salaryAmount,
        bool isActive
    ) external onlyOwner {
        require(staffAddr != address(0), "STAFF_ZERO");
        require(!staffs[staffAddr].isRegistered, "STAFF_ALREADY_REGISTERED");
        require(salaryAmount > 0, "SALARY_ZERO");

        staffs[staffAddr] = Staff({
            id: staffAddr,
            name: name,
            role: role,
            salaryAmount: salaryAmount,
            isActive: isActive,
            lastPaidAt: 0,
            isRegistered: true
        });

        // Add staff to list for "get all staff"
        staffIndex.push(staffAddr);

        emit StaffRegistered(staffAddr, salaryAmount, isActive, block.timestamp);
    }
function setStaffActive(address staffAddr, bool isActive) external onlyOwner {
        require(staffs[staffAddr].isRegistered, "STAFF_NOT_FOUND");
        staffs[staffAddr].isActive = isActive;
    }

    // Admin can change staff salary amount
    function setStaffSalary(address staffAddr, uint256 newSalary) external onlyOwner {
        require(staffs[staffAddr].isRegistered, "STAFF_NOT_FOUND");
        require(newSalary > 0, "SALARY_ZERO");
        staffs[staffAddr].salaryAmount = newSalary;
    }

    // function payStaff(address staffAddr) external onlyOwner nonReentrant {
    //     Staff storage s = staffs[staffAddr];
    //     require(s.isRegistered, "STAFF_NOT_FOUND");
    //     require(s.isActive, "STAFF_INACTIVE");

    //     uint256 salary = s.salaryAmount;
    //     require(salary > 0, "SALARY_ZERO");

    //     // Check if contract has enough token balance to pay salary
    //     require(paymentToken.balanceOf(address(this)) >= salary, "TREASURY_LOW");

    //     // Send tokens from contract -> staff
    //     _safeTransfer(address(paymentToken), staffAddr, salary);

    //     // Save last payment timestamp
    //     s.lastPaidAt = block.timestamp;

    //     emit StaffPaid(staffAddr, salary, block.timestamp);
    // }

    // Convenience: get one staff record
    function getStaff(address staffAddr) external view returns (Staff memory) {
        return staffs[staffAddr];
    }
    function listStaff(uint256 start, uint256 count) external view returns (address[] memory) {
        uint256 total = staffIndex.length;
        if (start >= total) return new address[](0);

        uint256 end = start + count;
        if (end > total) end = total;

        address[] memory result = new address[](end - start);
        for (uint256 i = start; i < end; i++) {
            result[i - start] = staffIndex[i];
        }
        return result;
    }

    // Total number of staff registered
    function totalStaff() external view returns (uint256) {
        return staffIndex.length;
    }
 function contractTokenBalance() external view returns (uint256) {
        return paymentToken.balanceOf(address(this));
    }
 function withdrawTokens(address to, uint256 amount) external onlyOwner nonReentrant {
        require(to != address(0), "TO_ZERO");
        require(amount > 0, "AMOUNT_ZERO");
        require(paymentToken.balanceOf(address(this)) >= amount, "TREASURY_LOW");

        _safeTransfer(address(paymentToken), to, amount);
        emit TreasuryTokenWithdrawn(to, amount);
    }
    function withdrawEther(address payable to, uint256 amount) external onlyOwner nonReentrant {
        require(to != address(0), "TO_ZERO");
        require(amount > 0, "AMOUNT_ZERO");
        require(address(this).balance >= amount, "ETH_LOW");

        (bool ok, ) = to.call{value: amount}("");
        require(ok, "ETH_SEND_FAIL");
        emit TreasuryEtherWithdrawn(to, amount);
    }
  receive() external payable {}
   function _isValidLevel(uint16 level) internal pure returns (bool) {
        return (level == 100 || level == 200 || level == 300 || level == 400);
    }

      function _safeTransfer(address token, address to, uint256 amount) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(ERC20.transfer.selector, to, amount));
        require(success, "TRANSFER_CALL_FAIL");
        if (data.length > 0) {
            require(abi.decode(data, (bool)), "TRANSFER_FALSE");
        }
    }
    function _safeTransferFrom(address token, address from, address to, uint256 amount) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(ERC20.transferFrom.selector, from, to, amount));
        require(success, "TRANSFERFROM_CALL_FAIL");
        if (data.length > 0) {
            require(abi.decode(data, (bool)), "TRANSFERFROM_FALSE");
        }
    }
    
    event StudentRemoved(address indexed student, uint256 timestamp);




function removeStudent(address student) external onlyOwner nonReentrant {
    
    require(students[student].isRegistered, "STUDENT_NOT_FOUND");

    // delete mapping record
    delete students[student];

    // remove from index array (swap & pop)
    _removeFromArray(studentIndex, student);

    emit StudentRemoved(student, block.timestamp);
}

event StudentFeePaid(address indexed student, uint16 level, uint256 amount, uint256 timestamp);

function payStudentFee() external nonReentrant {
    Student storage s = students[msg.sender];
    require(s.isRegistered, "NOT_REGISTERED");

    uint256 fee = feeByLevel[s.level];
    require(fee > 0, "FEE_NOT_SET");

    _safeTransferFrom(address(paymentToken), msg.sender, address(this), fee);

    s.status = FeePaymentStatus.Paid;
    s.lastPaymentTime = block.timestamp;
    s.totalPaid += fee;

    emit StudentFeePaid(msg.sender, s.level, fee, block.timestamp);
}
event StaffEmployed(address indexed staff, uint256 salaryAmount, uint256 timestamp);

function employStaff(
    address staffAddr,
    string calldata name,
    string calldata role,
    uint256 salaryAmount
) external onlyOwner {
    require(staffAddr != address(0), "STAFF_ZERO");
    require(!staffs[staffAddr].isRegistered, "STAFF_EXISTS");
    require(salaryAmount > 0, "SALARY_ZERO");

    staffs[staffAddr] = Staff({
        id: staffAddr,
        name: name,
        role: role,
        salaryAmount: salaryAmount,
        isActive: true,
        lastPaidAt: 0,
        isRegistered: true
    });

    staffIndex.push(staffAddr);
    emit StaffEmployed(staffAddr, salaryAmount, block.timestamp);
}
event StaffStatusChanged(address indexed staff, bool isActive, uint256 timestamp);

function suspendStaff(address staffAddr) external onlyOwner {
    require(staffs[staffAddr].isRegistered, "STAFF_NOT_FOUND");
    staffs[staffAddr].isActive = false;
    emit StaffStatusChanged(staffAddr, false, block.timestamp);
}

function activateStaff(address staffAddr) external onlyOwner {
    require(staffs[staffAddr].isRegistered, "STAFF_NOT_FOUND");
    staffs[staffAddr].isActive = true;
    emit StaffStatusChanged(staffAddr, true, block.timestamp);
}
function payStaff(address staffAddr) external onlyOwner nonReentrant {
    Staff storage s = staffs[staffAddr];
    require(s.isRegistered, "STAFF_NOT_FOUND");
    require(s.isActive, "STAFF_SUSPENDED");

    uint256 salary = s.salaryAmount;
    require(paymentToken.balanceOf(address(this)) >= salary, "TREASURY_LOW");

    _safeTransfer(address(paymentToken), staffAddr, salary);
    s.lastPaidAt = block.timestamp;

    emit StaffPaid(staffAddr, salary, block.timestamp);
}
    function _removeFromArray(address[] storage arr, address item) internal {
    uint256 len = arr.length;
    for (uint256 i = 0; i < len; i++) {
        if (arr[i] == item) {
            arr[i] = arr[len - 1];
            arr.pop();
            return;
        }
    }
    revert("NOT_IN_LIST");
}
    
    }
