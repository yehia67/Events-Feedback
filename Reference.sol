pragma solidity 0.4.24;
import "contracts/Course.sol";


//solidity does not allow you to create a contract instance from the same type "Circular reference"
//we use InstitutionFactory to allow an institution to create a sub institution
contract InstitutionFactory{

    event institutionCreated(string name, address institution, address parent);

    function createInstitution(
        string _name,
        address head,
        address creator,
        address[] _boardMembers,
        uint _votingTimeSeconds)
    public returns(address){

        /*
        * this function is called when an institution (smart contract) is creating a sub-institution (smart contract)
        * the parent institution PUBLIC_KEY is assigned as the creator in the child institution which guarantees linking
        sub-institutions to their parents
        * the require below guarantees that the CREATOR is the MSG.SENDER OR is NONE (i.e. this is a root institution)
        */
        require(msg.sender == creator || creator == address(0));

        Institution institutionAddress = new Institution(_name , head , creator , _boardMembers, _votingTimeSeconds);
        emit institutionCreated(_name, institutionAddress, creator);
        return institutionAddress;
    }
}


/// @title Institution
contract Institution{

    address public creator;  // The address of parent institution
    string public name;  // institution name

    // INSTITUTION HEAD & BOARD
    address public head; // institution head
    /**
    we can't loop on the MAP structure
    so we are using both a Mapping for direct access and an array to loop on board members
    */
    mapping(address => bool) public boardMembers; //institution boardMembers
    address[] public boardMembersArray;

    // VOTING FIELDS

    uint public votingTimeSeconds; // voting duration in seconds
    uint public votingThreshold; // min number of votes before a vote is accepted

    struct voting  {
        uint votingEndDate;
        uint Type; // type of the voting : 0 = add member, 1 = remove member, 2 = change head
        uint yesCount; // counter for voting on the address
        mapping (address => bool) voters; // a boolean for addresses to prevent double voting
    }

    mapping(address => voting) public memberVoting; // map connect address with voting
    address[] public memberVotingArray; // array of the voting holding instance for every voting on a person started


    modifier onlyHead(){
        require(msg.sender == head);
        _;
    }

    modifier onlyMember(){
        require(boardMembers[msg.sender] == true);
        _;
    }

    modifier headORmember(){
        require(boardMembers[msg.sender] == true || head == msg.sender);
        _;
    }

    function getMemberVotingEndDate(address member) public view returns(uint){
        return memberVoting[member].votingEndDate;
    }

    function getMemberVotingType(address member) public view returns(uint){
        return memberVoting[member].Type;
    }

    function getMemberVotingYesCount(address member) public view returns(uint){
        return memberVoting[member].yesCount;
    }

    function getHead() public view returns(address){
        return head;
    }

    function getCreator() public view returns(address){
        return creator;
    }

    function getName()public view returns(string){
        return name;
    }

    function getMemVotingArray()public view returns(address[]){
        return memberVotingArray;
    }

    function getBoardMembersArray()public view returns(address[]){
        return boardMembersArray;
    }

    function getVotingThreshold()public view returns(uint){
        return votingThreshold;
    }


    constructor(string _name , address _head , address _creator , address[] _boardMembers, uint _votingTimeSeconds) public {
        require(_boardMembers.length >= 2);

        name = _name;
        creator = _creator;

        head = _head;
        for(uint i=0 ; i < _boardMembers.length ; i++){
            if (boardMembers[_boardMembers[i]])
                continue;
            boardMembers[_boardMembers[i]] = true;
            boardMembersArray.push(_boardMembers[i]);
        }

        votingThreshold = (boardMembersArray.length + 1)/2 + 1;
        votingTimeSeconds = _votingTimeSeconds;
    }


    function createSubInstitution(string _name , address _head, InstitutionFactory factory , address[] _boardMembers, uint _votingTimeSeconds)public onlyHead returns(address){
        address institutionAddress = factory.createInstitution(_name , _head , this , _boardMembers, _votingTimeSeconds);
        //event is called from the factory
        return institutionAddress;
    }

    event addBoardMemberVotingStarted(address requester, address newMember, uint votingEndDate);

    function addBoardMembers(address newMember) public onlyHead{
        require(!boardMembers[newMember],"This address is already a board member");
        require(memberVoting[newMember].votingEndDate == 0 , "There is an open voting on this address running");
        checkPassedVoting();  // remove previous votings that passed their votingThreshold

        // voting end date = current time + voting duration
        memberVoting[newMember].votingEndDate =  now + votingTimeSeconds;
        memberVoting[newMember].yesCount = 1; // equal 1 as it's the head's vote
        memberVoting[newMember].Type = 0;
        memberVoting[newMember].voters[msg.sender] = true;
        memberVotingArray.push(newMember);

        emit addBoardMemberVotingStarted(msg.sender, newMember, memberVoting[newMember].votingEndDate);
    }

    event removeBoardMemberVotingStarted(address requester, address member, uint votingEndDate);

    function removeBoardMembers(address member) public onlyHead{
        require(boardMembers[member],"This address is already a board member");
        require(memberVoting[member].votingEndDate == 0 , "There is an open voting on this address running");
        checkPassedVoting();

        memberVoting[member].votingEndDate = now + votingTimeSeconds; // voting end date = current time + voting duration
        memberVoting[member].yesCount = 1; // equal 1 as it's the head's vote
        memberVoting[member].Type = 1;
        memberVoting[member].voters[msg.sender] = true;
        memberVotingArray.push(member);

        emit removeBoardMemberVotingStarted(msg.sender, member , memberVoting[member].votingEndDate);
    }

    event changeHeadVotingStarted(address requester, address newHead, uint votingEndDate);

    function changeHead(address newHead) public headORmember{
        require(newHead != head , "The address is the same as the head address");
        require(memberVoting[newHead].votingEndDate == 0,"There is an open voting on this address running");
        checkPassedVoting();

        memberVoting[newHead].votingEndDate = now + votingTimeSeconds;
        memberVoting[newHead].yesCount = 1; // equal 1 as it's the head's vote
        memberVoting[newHead].Type = 2;
        memberVoting[newHead].voters[msg.sender] = true;
        memberVotingArray.push(newHead);

        emit changeHeadVotingStarted(msg.sender, newHead, memberVoting[newHead].votingEndDate);
    }


    function removeMemberFromVoting(address member) private {
        uint sz = memberVotingArray.length;
        // removing member element from array & map
        for(uint i=0 ; i < sz ; i++){
            if(memberVotingArray[i] == member){
                memberVotingArray[i] = memberVotingArray[sz-1];
                memberVotingArray.length--;
                break;
            }
        }
        delete memberVoting[member];
    }



    event memberVoted(address from , address to);
    event votingSucceeded(address to, uint votingType);

    function vote(address member) public headORmember {

        require(now < memberVoting[member].votingEndDate , "The end date already passed");
        require(memberVoting[member].voters[msg.sender] == false , "you already voted on this address");

        memberVoting[member].yesCount++;
        memberVoting[member].voters[msg.sender] = true ;
        emit memberVoted(msg.sender , member);

        // check if the yescount passed the voting Threshold
        // then remove it from the memberVoting array
        // and the member voting map
        if(memberVoting[member].yesCount >= votingThreshold){

            removeMemberFromVoting(member);

            // add member
            if(memberVoting[member].Type == 0){
                // add member to the board member array and map
                boardMembers[member] = true;
                boardMembersArray.push(member);

                // update voting threshold
                votingThreshold = (boardMembersArray.length + 1)/2 + 1;

                // call event to stop voting for this member
                emit votingSucceeded(member, memberVoting[member].Type);
            }

            //remove member
            else if(memberVoting[member].Type == 1){
                // remove member from the board member array, map and member voting array and map
                boardMembers[member] = false;
                uint sz = boardMembersArray.length;
                for(uint i=0 ; i < sz ; i++){
                    if(boardMembersArray[i] == member){
                        boardMembersArray[i] = boardMembersArray[sz-1];
                        boardMembersArray.length--;
                        break;
                    }
                }

                // update voting threshold
                votingThreshold = (boardMembersArray.length + 1)/2 + 1;
                // call event to stop voting for this member
                emit votingSucceeded(member, memberVoting[member].Type);
                // remove member from the map
            }

            // change head
            else{
                head = member;
                // call event to stop voting for this member
                emit votingSucceeded(member, memberVoting[member].Type);
            }
        }
    }



    event votingFailed(address to, uint votingType);

    function checkPassedVoting() private{
        uint sz = memberVotingArray.length;
        for(uint i=0 ; i < sz ; i++)
        /** Check if the end date of the selected in voting Array
          * then remove it from the member voting array , member
          * voting map and decrease size of the array by 1
          */
            if(now > memberVoting[memberVotingArray[i]].votingEndDate ){

                emit votingFailed(memberVotingArray[i], memberVoting[memberVotingArray[i]].Type);

                memberVotingArray[i] = memberVotingArray[sz-1];
                memberVotingArray.length--; // removes the last element from the array
                delete memberVoting[memberVotingArray[i]];
                i--;
            }
    }


    event courseCreated(address institution, address course, string name);

    function createCourseOffering(
        string _name,
        address[] _instructors,
        address[] _teachingAssistants)
    public onlyHead returns(address){
        address newCourse = new Course(_name, _instructors, _teachingAssistants);
        emit courseCreated(this, newCourse, _name);
        return newCourse;
    }



}





///////////////////////////////////////////////












pragma solidity 0.4.24;

/** @title Course. */
contract Course{

    // Address of creator institution.
    address public creator;
    string public name;

    // If an address maps to true then this address is a member.
    mapping( address => bool ) public instructors;
    mapping( address => bool ) public teachingAssistants;

    uint public startDate;
    uint public endDate;

    // Represents Assignments, tasks, exams, etc...
    struct GradedItem{
        string name;
        uint maxGrade;
        uint weight; // How much it contributes to course's final grade.
    }

    uint public remainingWeight = 100; // remaining courses weight

    uint public index = 0; // Size of graded items map.
    mapping(uint => GradedItem) public gradedItems; // Id to graded item, id is serial.

    // Student PK => ( Graded Item ID => Grade ).
    mapping(address => mapping(uint => uint)) public studentsIndividualGrades;

    // Student to course total grade
    mapping(address => uint) public studentsTotalGrades;


    modifier onlyInstructor{
        require(instructors[msg.sender] == true);
        _;
    }

    modifier onlyTeachingAssistant{
        require(teachingAssistants[msg.sender] == true);
        _;
    }

    modifier instructorORteachingAssistant{
        require(teachingAssistants[msg.sender] == true || instructors[msg.sender] == true);
        _;
    }

    modifier beforeStart{
        require(startDate == 0);
        _;
    }

    modifier courseStarted{
        require(startDate != 0);
        _;
    }

    modifier beforeEnd{
        require(endDate == 0);
        _;
    }

    modifier courseEnded{
        require(endDate != 0);
        _;
    }


    constructor(string _name , address [] _instructors, address [] _teachingAssistants) public {

        require(_instructors.length >= 1, "At least one instructor");
        require(_teachingAssistants.length >= 1, "At least one TA");

        uint i;
        for(i=0 ; i<_instructors.length ; i++){
            instructors[_instructors[i]] = true;
        }

        for(i=0 ; i<_teachingAssistants.length ; i++){
            teachingAssistants[_teachingAssistants[i]] = true;
        }
        name = _name;
        creator = msg.sender;
    }

    function getIndex()public view returns(uint){
        return index;
    }

    function getGrades(address _Student , uint ID)public view returns(uint){
        return studentsIndividualGrades[_Student][ID];
    }

    function getItemName(uint ID)public view returns(string){
        return (gradedItems[ID].name);
    }

    function getItemMaxGrade(uint ID)public view returns(uint){
        return (gradedItems[ID].maxGrade);
    }

    function getItemWeight(uint ID)public view returns(uint){
        return (gradedItems[ID].weight);
    }


    function getTotalGrade(address student)public view returns(uint){
        return studentsTotalGrades[student];
    }

    function getCreator()public view returns(address){
        return creator;
    }

    event InstructorsAddedEvent(address requester, address[] instructors);

    function addInstructor(address[] _instructors)public onlyInstructor beforeEnd{
        for(uint i=0 ; i< _instructors.length ;i++){
            instructors[_instructors[i]] = true;
        }
        emit InstructorsAddedEvent(msg.sender, _instructors);
    }


    event InstructorsRemovedEvent(address requester, address[] instructors);

    function removeInstructor(address[] _instructors) public onlyInstructor beforeEnd{
        for(uint i=0 ; i<_instructors.length ; i++){
            instructors[_instructors[i]] = false;
        }
        emit InstructorsRemovedEvent(msg.sender, _instructors);
    }


    event TeachingAssistantsAddedEvent(address requester, address[] teachingAssistants);

    function addTeachingAssistant(address[] _teachingAssistants)public onlyInstructor beforeEnd{
        for(uint i=0  ;i<_teachingAssistants.length ; i++){
            teachingAssistants[_teachingAssistants[i]] = true;
        }
        emit TeachingAssistantsAddedEvent(msg.sender, _teachingAssistants);
    }


    event TeachingAssistantsRemovedEvent(address requester, address[] teachingAssistants);

    function removeTeachingAssistant(address[] _teachingAssistants)public onlyInstructor beforeEnd{
        for(uint i=0  ;i<_teachingAssistants.length ; i++){
            teachingAssistants[_teachingAssistants[i]] = false;
        }
        emit TeachingAssistantsRemovedEvent(msg.sender, _teachingAssistants);
    }


    event CourseStartedEvent(uint time);

    function startCourse() public onlyInstructor beforeStart{
        startDate = now;
        emit CourseStartedEvent(startDate);
    }


    event CourseEndedEvent(uint time);

    function endCourse()public onlyInstructor courseStarted beforeEnd{
        endDate = now;
        emit CourseEndedEvent(endDate);
    }


    event GradedItemAddedEvent(uint id, string name,uint maxgrade, uint weight);

    function addGradedItem(string _name,uint _maxGrade, uint _weight)public onlyInstructor beforeEnd{
        require(remainingWeight >= _weight);
        remainingWeight -= _weight;

        gradedItems[index] = GradedItem(_name, _maxGrade, _weight);
        emit GradedItemAddedEvent(index, _name, _maxGrade, _weight);
        index++;
    }


    event GradedItemUpdatedEvent(uint id, uint newWeight);

    function updateGradedItemWeight(uint _id, uint _weight)public onlyInstructor beforeEnd{
        require(_id >= 0 && _id < index );
        require((remainingWeight + gradedItems[_id].weight ) >= _weight);

        remainingWeight += gradedItems[_id].weight;
        remainingWeight -= _weight;
        gradedItems[_id].weight = _weight;
        emit GradedItemUpdatedEvent(_id, _weight);
    }


    event StudentAddedEvent(address requester, address student);

    function addStudent(address _student) public instructorORteachingAssistant beforeEnd{
        studentsTotalGrades[_student] = 1;
        emit StudentAddedEvent(msg.sender, _student);
    }

    event StudentRemovedEvent(address requester, address student);

    function removeStudent(address _student)public instructorORteachingAssistant beforeEnd{
        studentsTotalGrades[_student] = 0;
        emit StudentRemovedEvent(msg.sender, _student);
    }

    event studentGradeUpdatedEvent(address _student, uint _grade, uint _gradeId, string desc);

    function addOrUpdateStudentGrade(
        address _student,
        uint _grade,
        uint _gradeId,
        string desc)
    public instructorORteachingAssistant courseStarted{

        require( studentsTotalGrades[_student] > 0);
        require(_gradeId >= 0 && _gradeId < index );
        require( _grade <= gradedItems[_gradeId].maxGrade);

        studentsIndividualGrades[_student][_gradeId] = _grade;

        if(now > endDate && endDate !=0){
            // If an item graded is updated after the course end date, student's total grade is recalculated.
            calculateTotalGrades(_student);
        }
        emit studentGradeUpdatedEvent(_student, _grade, _gradeId, desc);
    }

    event studentGradeComputedEvent(address Student, uint grade);

    function calculateTotalGrades(address student) public courseEnded{
        require(remainingWeight == 0);
        require(studentsTotalGrades[student] != 0 );
        studentsTotalGrades[student] = 0;

        for(uint id = 0 ; id < index ; id++){
            // Adding the grade of each graded item to the student's total grade.
            // Grade of each item is multiplied by item's weight then divided by the item's max grade.
            if(studentsIndividualGrades[student][id] != 0)
                studentsTotalGrades[student] +=Ceil( (gradedItems[id].weight * studentsIndividualGrades[student][id]), (gradedItems[id].maxGrade) );
        }

        emit studentGradeComputedEvent(student, studentsTotalGrades[student]);
    }

    function Ceil(uint x , uint y) private pure returns(uint){
        return (x+y-1)/y;
    }





}
