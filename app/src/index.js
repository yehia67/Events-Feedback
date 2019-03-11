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
    createSession: async function(_sessionName, _description, _startTime, _endTime, _lecturer, _attendes) {
        const { createSession } = this.meta.methods;
        await createSession(_sessionName, _description, _startTime, _endTime, _lecturer, _attendes).send({ from: this.account });
    },

    getSession: async function(_sessionName) {
        let discription = 10;
        const { getSession } = this.meta.methods;
        discription = await getSession(_sessionName).call();
    },

    //Events Time
    parseDate: function(input) {
        var parts = input.match(/(\d+)/g);
        // New Date(year, month [, date [, hours[, minutes[, seconds[, ms]]]]])
        return new Date(parts[0], parts[1] - 1, parts[2]); // months are 0-based
    },


    onSubmit: async function() {
        var sessionName = $('#create_session_name').val();

        var discription = $('#discription').val();

        var start_date = this.parseDate($('#start_date').val());
        var start = (start_date.getTime()) / 1000;

        var end_date = this.parseDate($('#end_date').val());
        var end = (end_date.getTime()) / 1000;
        var noOfDays = $('#no-of-days').val();
        var nofDaysInSecond = noOfDays * 24 * 60 * 60;

        var lecturers = $('#lecturers').val();

        var attendes = $('#attendes').val().split(',');

        this.createSession(sessionName, discription, start, nofDaysInSecond + end, lecturers, attendes);

        this.getSession(sessionName);
    },
    //Take Feedback
    takeVote: async function() {
        var _sessionName = $('#feedback_session_name').val();
        var _feedback = $('#feedback').val();
        const { takeVote } = this.meta.methods;
        await takeVote(_sessionName, _feedback).send({ from: this.account });
        alert("done");
    },
    //See Result
    seeResult: async function() {
        var _sessionName = $('#see_session_name').val();
        let result = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
        const { seeResult } = this.meta.methods;
        result = await seeResult(_sessionName).call();
        alert(result);
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