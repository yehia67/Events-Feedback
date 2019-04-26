pragma solidity >=0.4.22 <0.6.0;

contract Organization {

     address creator;
     event sessionnCreated(string name,address sessionAddress ,address creator);
     
     /*  modifier onlyCreator(){
        require(msg.sender == creator);
        _;
    } 0x88260a1eb5a2b6c66fa184e4b383a9e3ffa2ce15,0xf695b57bd17dae4738b0eebb88f264b5ba4557d6,0x030828d9fbd35fc8a72e29bd6cd28fb031cf4f7e,0x627a1fd473f88d3fd648551ce7b6814d62a83034 */
     function createdSession(
      string memory _sessionName,
      string memory _description,
      uint _startTime,
      uint _endTime,
      address[] memory _lecturer,
      address[] memory _attendes
     ) public   returns(address) {
        
        Session sessionAddress = new Session(_sessionName , _description , _startTime , _endTime, _lecturer,_attendes );
        emit sessionnCreated(_sessionName,address(sessionAddress),creator);
        return address(sessionAddress);
     }
  
}

//Session

contract Session {
     
      address public creator;  // The address of parent Organization
     
      string sessionName;
      string description;
      uint startTime;
      uint endTime;
      address[] lecturer;
      address[] attendes; 

      int[] result; 
      mapping(address => int) public attendes_feedback; //institution boardMembers
      modifier onTime(uint _startTime){
            require(now < _startTime);
            _;
      }
      constructor (string memory _sessionName, string memory _description, uint _startTime,uint _endTime,address[] memory   _lecturer,address[] memory  _attendes) public onTime(_startTime){
              
              sessionName =  _sessionName;
              description = _description;
              startTime = _startTime;
              endTime = _endTime;
              attendes = _attendes;
              lecturer = _lecturer;
              initAttendes(attendes);
      } 
      
    function initAttendes(address[] memory _attendes) private{
           for(uint i=0 ; i < _attendes.length ; i++){
            attendes_feedback[_attendes[i]] = -1;
        }
    }
    
    function Time() public view returns (bool){
       return (now >=  startTime  && now <= endTime);          
     }

    modifier checkTime(){
        require(Time());
        _;
      }
    function take_feedback(address _voter,uint8 _feedback)  public checkTime {
          require(attendes_feedback[_voter] != 0);
          attendes_feedback[_voter] = _feedback;
          result[_feedback]++;
    }
 
  function seeResult() public view returns(int[] memory){
          return result;
  }
 }