pragma solidity >=0.4.22 <0.6.0;

contract FeedBack {

  //Create session
  struct session {
      string sessionName;
      string description;
      uint startTime;
      uint endTime;
      string lecturer;
      address[] attendes;
  }
 
  mapping ( string => session) sessions;
  mapping ( string => uint8[]) feedback;
 
  function createSession(string memory _sessionName,string memory _description,uint _startTime,uint _endTime,string memory  _lecturer,address[] memory  _attendes) public
  {
      session storage Session = session(_sessionName,_description,_startTime,_endTime,_lecturer,_attendes);
      sessions[_sessionName] = Session;
      initFeedback(_sessionName);
    
  }
  // get session  
  function getSession(string memory _sessionName) public view returns(string memory){
      return sessions[_sessionName].description;
  }
  // check session 
  function checkSession(string memory _sessionName) public view returns(bool){
     /*  if (sessions[_sessionName]  !=   0 ) {
          return true;
          
      } else {
          return false;
      } */
  }

  // Make feedback
 
   function initFeedback(string memory _sessionName) private{
       feedback[_sessionName] = new uint8[](5);
       feedback[_sessionName][0] = (10/50) * 100;
       feedback[_sessionName][1] = (17/50) * 100;
       feedback[_sessionName][2] = (13/50) * 100;
       feedback[_sessionName][3] = (35/50) * 100;
       feedback[_sessionName][4] = (15/50) * 100;

    }
     
    function feedBack(string memory _sessionName,uint _feedback) private{
      feedback[_sessionName][_feedback]++;
  }   

  //Make Time
  // Will return `true` if the Time has passed
  // called, `false` if the Time hasn't pass yet
  function Time(string memory _sessionName) public view returns (bool){
       return (now >=   sessions[_sessionName].startTime  && now <= sessions[_sessionName].endTime);          
  }
   
   constructor() public {
       
   }  








  //Validate voters.
  // Find Attendes public address return true if exist
  function findAddress(address _attende,address[] memory _attendes)  public pure returns (bool) {
         for(uint i = 0; i < _attendes.length ; i++){
             if(_attende == _attendes[i]){
                 return true;
             }
         }
         return false;
  }







  function validate(string memory _sessionName,address[] memory _attendes) private view returns(bool){
            //Attende
            require(!Time(_sessionName));
            if(findAddress(msg.sender,_attendes)){
                  return true;
            }
            else{
                return false;
            }
  }

  //Take vote
  function takeVote(string memory _sessionName,uint _feedback)public{
      require(validate(_sessionName,sessions[_sessionName].attendes));
      feedBack(_sessionName,_feedback);
            
  }

  //See result
  function seeResult(string memory _sessionName) public view returns(uint8[] memory){
      return feedback[_sessionName];
  }
  
}