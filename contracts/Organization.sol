pragma solidity >=0.4.22 <0.6.0;

contract Organization {

     address creator;
     event createdSession(string name, address creator);
     
      modifier onlyCreator(){
        require(msg.sender == creator);
        _;
    }
     function createdSession(
      string _sessionName,
      string _description,
      uint _startTime,
      uint _endTime,
      address[] _lecturer,
      address[] _attendes;
     ) public  onlyCreator returns(address) {
        
        Session sessionAddress = new Session(_sessionName , _description , _startTime , _endTime, _lecturer,_attendes );
        emit sessionnCreated(_name, institutionAddress, creator);
        return sessionAddress;
     }
  
}

//Session

contract Session {
     
      address public creator;  // The address of parent Organization
     
      string sessionName,
      string description,
      uint startTime,
      uint endTime,
      address[] lecturer,
      address[] _attendes;
        
      mapping(address => uint) public attendesFeedback; //institution boardMembers
  
      constructor (string _sessionName, string _description, uint _startTime,uint _endTime,address _lecturer,address _attendes) public{
              sessionName =  _sessionName;
              description = _description;
              startTime = _startTime;
              endTime = _endTime;
              attendes = __attendes;
              lecturer = _lecturer;
      }    
}