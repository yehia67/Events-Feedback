// The object 'Contracts' will be injected here, which contains all data for all contracts, keyed on contract name:
// Contracts['HelloWorld'] = {
//  abi: [],
//  address: "0x..",
//  endpoint: "http://...." 31237747
// }
function FeedBack(Contract) {
    this.web3 = null;
    this.instance = null;
    this.Contract = Contract;
}

FeedBack.prototype.init = function() {
    // We create a new Web3 instance using either the Metamask provider
    // or an independent provider created towards the endpoint configured for the contract.
    this.web3 = new Web3(
        (window.web3 && window.web3.currentProvider) ||
        new Web3.providers.HttpProvider(this.Contract.endpoint));

    // Create the contract interface using the ABI provided in the configuration.
    var contract_interface = this.web3.eth.contract(this.Contract.abi);

    // Create the contract instance for the specific address provided in the configuration.
    this.instance = contract_interface.at(this.Contract.address);
};





FeedBack.prototype.createSession = function(_sessionName,_description,_startDate,_rateTime,lecturer,attendes,cb){ 
    var that = this; 
    this.instance.createSession(_sessionName,_description,_startDate,_rateTime,lecturer,attendes,
     { from: window.web3.eth.accounts[0], gas: 50000, gasPrice: 100000, gasLimit: 100000 },
        function(error, txHash) {
        $("#result").html('Creating seassion in progress...');

        if(error){
             console.error(error);
                    $("#result").html("Shit error, try it again.");
                    return;
        }else{
            that.waitForReceipt(txHash, function(receipt) {
                        if(receipt.status) {
                          $("#result").html("Done your session is avaialbe now");  
                        }
                        else {
                            $("#result").html("Sorry somthing went wrong. Please try it again.");
                        }
                    });
        }
                

        }
     
     )
} 

//Calculate Time

// Parse a date in yyyy-mm-dd format
   FeedBack.prototype.parseDate = function (input) {
  var parts = input.match(/(\d+)/g);
  // New Date(year, month [, date [, hours[, minutes[, seconds[, ms]]]]])
  return new Date(parts[0], parts[1]-1, parts[2]); // months are 0-based
}

//Get Time in days
FeedBack.prototype.caclculateTime = function(_startTime,_endTime,_Time){
  var start = parseDate(_startTime);
  var end = parseDate(_endTime);
  var timeDiff = Math.abs(end.getTime() - start.getTime());
  var diffDays = Math.ceil(timeDiff / (1000 * 3600 * 24)); 
  var time = parseInt(_Time);
  return diffDays + _Time;

}
//Get Time in days
FeedBack.prototype.onSubmit = function(){
    $("#btn").click(function(){
        var seasonName =  $('#session_name').val();
        var discription =  $('#discription').val();
        var start_date =  $('#start_date').val();
        var end_date =  $('#end_date').val();
        var time =  $('#time').val();
        var lecturers =  $('#lecturers').val().split(','); 
        var attendes =  $('#attendes').val().split(',');
        var Time = caclculateTime(start_date,end_date,time);
        var startDateInDayes = Math.ceil(parseDate(start_date).getTime()/(1000 * 3600 * 24));
        createSession(seasonName,discription,startDateInDayes,Time,lecturer,attendes,);
               
    });


}

// Waits for receipt from transaction
FeedBack.prototype.waitForReceipt = function(hash, cb) {
    var that = this;

    // Checks for transaction receipt
    this.web3.eth.getTransactionReceipt(hash, function(err, receipt) {
        if (err) {
            error(err);
        }
        if (receipt !== null) {
            // Transaction went through
            if (cb) {
                cb(receipt);
            }
        } else {
            // Try again in 2 second
            window.setTimeout(function() {
                that.waitForReceipt(hash, cb);
            }, 2000);
        }
    });
}



FeedBack.prototype.onReady = function() {
    this.init();
 
};

var feedBack = new FeedBack(Contracts['FeedBack']);

$(document).ready(function() {
    feedBack.onReady();
    feedBack.onSubmit();
});