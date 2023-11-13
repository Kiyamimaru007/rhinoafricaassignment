import { LightningElement, track, wire } from 'lwc';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import { ShowToastEvent } from "lightning/platformShowToastEvent";

//Import picklist fields
import COUNTRY_FIELD from '@salesforce/schema/Enquiry__c.Country__c';
import HOLIDAY_FIELD from '@salesforce/schema/Enquiry__c.Holiday_Type__c';
import ENQUIRY_FIELD from '@salesforce/schema/Enquiry__c.Enquiry_Type__c';

//Import Apex classes
import createRecords from '@salesforce/apex/EnquiryLWCController.createRecords';

export default class EnquiryLWC extends LightningElement {
    
    //Picklist Option Vairables
    @track
    countryOptions = [];
    holidayOptions = [];
    enquiryOptions = [];

    //Now I'm going to use @wire methods to fetch the picklist options from the fields picklist options
    //This allows us to have dynamic code.
    @wire(getPicklistValues, {
        recordTypeId: "012000000000000AAA",
        fieldApiName: COUNTRY_FIELD
    })
    countryPicklistValues({ error, data }) {
        console.log('Hello>>> 1');
        if (data) {
            this.countryOptions = data.values;
        } else if (error) {
            console.error('Error fetching country picklist values:', error);
        }
    }

    @wire(getPicklistValues, {
        recordTypeId: "012000000000000AAA",
        fieldApiName: HOLIDAY_FIELD
    })
    holidayPicklistValues({ error, data }) {
        console.log('Hello>>> 2');
        if (data) {
            this.holidayOptions = data.values;
        } else if (error) {
            console.error('Error fetching holiday picklist values:', error);
        }
    } 

    @wire(getPicklistValues, {
        recordTypeId: "012000000000000AAA",
        fieldApiName: ENQUIRY_FIELD
    })
    enquiryPicklistValues({ error, data }) {
        if (data) {
            this.enquiryOptions = data.values;
        } else if (error) {
            console.error('Error fetching enquiry picklist values:', error);
        }
    }

    //Field Variables
    @track
    firstName;
    lastName;
    country;
    arrivalDate;
    numAdults;
    numChildren;
    email;
    phone;
    holidayType;
    departureDate;
    enquiryType;
    comments;

    //Although we can use 1 function to handle all the input changes with conditions to determine which of the variables above is altered.
    //It is better to have for each input field so that it is more reliable and scalable. If we add too much complexity to 1 function it may
    //not reliably work

    //Each function will handle the change of their corresponding variable
    handleFirstName(event) {
        console.log('Hello>>> handleFirstName'); //I always add this to confirm that the function is getting called
        this.firstName = event.target.value;
    }

    handleLastName(event) {
        console.log('Hello>>> handleLastName'); //I add the 'Hello>>>' so that it can be filtered in the chrome inspector which allows me to focus on just my components logs
        this.lastName = event.target.value;
    }

    handleCountry(event) {
        //Although the code looks repetative I have my ways (Extensions and keyboard shortcuts) of coding multiple lines at once
        console.log('Hello>>> handleCountry');
        this.country = event.target.value;
    }

    handleArrivalDate(event) {
        console.log('Hello>>> handleArrivalDate');
        this.arrivalDate = event.target.value;
    }

    handleNumAdults(event) {
        console.log('Hello>>> handleNumAdults');
        this.numAdults = event.target.value;
    }

    handleNumChildren(event) {
        console.log('Hello>>> handleNumChildren');
        this.numChildren = event.target.value;
    }

    handleEmail(event) {
        console.log('Hello>>> handleEmail')        
        this.email = event.target.value;
    }

    handlePhone(event) {
        console.log('Hello>>> handlePhone')
        this.phone = event.target.value;
    }

    handleHolidayType(event) {
        console.log('Hello>>> handleHolidayType')
        this.holidayType = event.target.value;
    }

    handleDepartureDate(event) {
        console.log('Hello>>> handleDepartureDate')
        this.departureDate = event.target.value;
    }

    handleEnquiryType(event) {
        console.log('Hello>>> handleEnquiryType')
        this.enquiryType = event.target.value;
    }

    handleComments(event) {
        console.log('Hello>>> handleComments')
        this.comments = event.target.value;
    }

    handleFormSubmit() {
        //In this function I'll be getting all the field variables values and send them through to the apex
        console.log('Hello>>> handleFormSubmit');
        let fieldTest = false;

        console.log('Hello>>> 1');
        //First we have to make sure that all required fields have been filled in and warn the user if they haven't been
        if(this.firstName == null || this.lastName == null || this.country == null || this.numAdults == null || this.email == null || this.holidayType == null || this.enquiryType == null){
            console.log('Hello>>> 2');
            alert('Please make sure to fill in all required fields');
            console.log('Hello>>> 3');
        }
        else if(this.numAdults < 0 && this.numAdults != null){
            alert('Number of Adults cannot be less than 0');
        }
        else if(this.numChildren < 0 && this.numChildren != null){
            alert('Number of Children cannot be less than 0');
        }
        else{
            fieldTest = true;
            console.log('Hello>>> 4');
        }

        console.log('Hello>>> 5');
        //Now that we have confirmed that all required fields are filled in, we can send everything to the apex and get a response
        if(fieldTest){
            console.log('Hello>>> Call Apex');
            //I make a quick object array then stringify it so that it can be sent through to the apex
            let fieldsArray = {
                                    "firstName" : this.firstName,
                                    "lastName" : this.lastName,
                                    "email" : this.email,
                                    "phone" : this.phone,
                                    "country" : this.country,
                                    "holidayType" : this.holidayType,
                                    "arrivalDate" : this.arrivalDate,
                                    "departureDate" : this.departureDate,
                                    "numOfAdults" : this.numAdults,
                                    "numOfKids" : this.numChildren,
                                    "enquiryType" : this.enquiryType,
                                    "comments" : this.comments
                                };
            console.log('Hello>>> 6');
            createRecords({ jsonObject : JSON.stringify(fieldsArray) })
            .then( result => {
                console.log('Hello>>> 7');
                if(result == "SUCCESS"){
                    alert("Records Created Successfully.");
                    location.reload();
                }
                else{
                    alert(result[1]);
                }
            })
            .catch( error => {
                console.log("error: ", error);
                alert("Error Trying To Create Records. Please Contact Salesforce Admin");
            });
        }
    }
}