pragma solidity >=0.4.21 <0.6.0;

contract FeedBack {

  //Create session
  struct session {
      string sessionName;
      string description;
      uint feedbackTime;
      uint feedbackDate;
      string lecturer;
      address[] attendes;
  }
 
  mapping ( string => session) sessions;
  mapping ( string => uint8[]) feedback;
 
  function createSession(string memory _sessionName,string memory _description,uint _feedbackTime,string memory  _lecturer,address[] memory  _attendes) public
  {
      sessions[_sessionName] = session(_sessionName,_description,_feedbackTime,0,_lecturer,_attendes);
      initFeedback(_sessionName);
      setFeedbackTime(_sessionName);
  }
  
  // Make feedback
 
   function initFeedback(string memory _sessionName) private{
       feedback[_sessionName] = new uint8[](11);
    }
     function feedBack(string memory _sessionNam,uint _feedback) private{
      feedback[_sessionNam][_feedback]++;
  }   

  //Make Time
  // Will return `true` if the Time has passed
  // called, `false` if the Time hasn't pass yet
  function Time(string memory _sessionName) public view returns (bool){
       return (now >=   sessions[_sessionName].feedbackDate );          
  }
  function setFeedbackTime(string memory _sessionName) private{
            sessions[_sessionName].feedbackDate = now +  sessions[_sessionName].feedbackTime;
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