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