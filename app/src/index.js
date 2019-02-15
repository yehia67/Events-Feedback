import Web3 from "web3";
import FeedBackArtifact from "../../build/contracts/FeedBack.json";

const App = {
    web3: null,
    account: null,
    meta: null,

    start: async function() {
        const { web3 } = this;

        try {
            // get contract instance
            const networkId = await web3.eth.net.getId();
            const deployedNetwork = FeedBackArtifact.networks[networkId];
            this.meta = new web3.eth.Contract(
                FeedBackArtifact.abi,
                deployedNetwork.address,
            );

            // get accounts
            const accounts = await web3.eth.getAccounts();
            this.account = accounts[0];


        } catch (error) {
            console.error("Could not connect to contract or chain.");
        }
    },

    //Create session
    createSession: async function(_sessionName, _description, _feedbackTime, _lecturer, _attendes) {
        const { createSession } = this.meta.methods;
        await createSession(_sessionName, _description, _feedbackTime, _lecturer, _attendes).call();
        alert("done creating session");
    },

    //Events Time
    parseDate: function(input) {
        var parts = input.match(/(\d+)/g);
        // New Date(year, month [, date [, hours[, minutes[, seconds[, ms]]]]])
        return new Date(parts[0], parts[1] - 1, parts[2]); // months are 0-based
    },
    caclculateTime: async function(_startTime, _endTime, _Time) {
        var start = this.parseDate(_startTime);
        var end = this.parseDate(_endTime);
        var timeDiff = Math.abs(end.getTime() - start.getTime());
        var diffDays = Math.ceil(timeDiff / (1000 * 3600 * 24));
        var time = parseInt(_Time);
        return diffDays + _Time;

    },
    onSubmit: async function() {
        var seasonName = $('#create_session_name').val();

        var discription = $('#discription').val();

        var start_date = $('#start_date').val();

        var end_date = $('#end_date').val();

        var time = $('#time').val();
        this.caclculateTime(start_date, end_date, time);
        //caclulate time

        var lecturers = $('#lecturers').val();

        var attendes = $('#attendes').val().split(',');

        console.log("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
        //var lects = Web3.utils.fromAscii(lecturers);
        this.createSession(seasonName, discription, time, Web3.utils.fromAscii(lecturers), attendes);

        alert("done");

    },

};

window.App = App;

window.addEventListener("load", function() {
    if (window.ethereum) {
        // use MetaMask's provider
        App.web3 = new Web3(window.ethereum);
        window.ethereum.enable(); // get permission to access accounts
    } else {
        console.warn(
            "No web3 detected. Falling back to http://127.0.0.1:9545. You should remove this fallback when you deploy live",
        );
        // fallback - use your fallback strategy (local node / hosted node + in-dapp id mgmt / fail)
        App.web3 = new Web3(
            new Web3.providers.HttpProvider("http://127.0.0.1:9545"),
        );
    }

    App.start();
});