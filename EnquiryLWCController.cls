public without sharing class EnquiryLWCController {
    
    //I delcare constants that will be used in the API callout
    public static final String ED_WEBSITE = '72';
    public static final String ED_PASSKEY = 'devpass';
    public static final String API_ENDPOINT = 'https://eddy.rhinoafrica.com/submit';

    @AuraEnabled
    public static List<String> createRecords(String jsonObject){
        //In this method I accept the json string from the LWC, convert it and create the necessary object records (Lead and Enquiry__c)
        System.debug('createRecords');
        //I use a string list as a return value so that I can I capture error messages and send them back to the LWC if necessary
        List<String> resultList = new List<String>(); 
        FormObject formValues = (FormObject)JSON.deserialize(jsonObject, FormObject.class);
        System.debug('Form Values: ' + formValues);

        //First the Lead has to be made. I will use the first and last name to make the Lead as well as some of the fields that i assume
        //can be used on the Lead
        Lead newLead = new Lead();
        newLead.FirstName = formValues.firstName;
        newLead.LastName = formValues.lastName;
        newLead.Email = formValues.email;
        newLead.Company = 'Enquiry Lead';
        if(formValues.phone != null){ //phone is not a required field therefor I need to null check before assigning it as a value for a field
            newLead.Phone = formValues.phone;
        }

        //Now I'm going to insert the Lead within a try catch block
        try{
            insert newLead;
        }
        catch(Exception e){
            System.debug('Exception on Line: ' + e.getLineNumber() + ' : ' + e.getMessage());
            //IF there is a failure in any of the try catch blocks I capture the error message and send it back to the LWC in the following format
            resultList.add('ERROR');
            resultList.add('ERROR! '  + e.getMessage());
            return resultList; //I only want the code to continue if the lead was created since it is a required field
        }

        //Now I can create the Enquiry__c record using the field values
        Enquiry__c newEnquiry = new Enquiry__c();
        newEnquiry.Lead__c = newLead.Id;
        newEnquiry.Name = 'TST-KB-' + System.now().format('HH:mm:ss');
        newEnquiry.Enquiry_Type__c = formValues.enquiryType;
        newEnquiry.First_Name__c = formValues.firstName;
        newEnquiry.Last_Name__c = formValues.lastName;
        newEnquiry.Email__c = formValues.email;
        newEnquiry.Country__c = formValues.country;
        if(formValues.phone != null){
            newEnquiry.Phone__c = formValues.phone;
        }
        newEnquiry.Holiday_Type__c = formValues.holidayType;
        newEnquiry.Number_of_Adults__c = formValues.numOfAdults;
        if(formValues.numOfKids != null){
            newEnquiry.Number_of_Children__c = formValues.numOfKids;
        }
        if(formValues.arrivalDate != null){
            newEnquiry.Arrival_Date__c = formValues.arrivalDate;   
        }
        if(formValues.departureDate != null){
            newEnquiry.Departure_Date__c = formValues.departureDate;
        }
        if(formValues.comments != null){
            newEnquiry.Comments__c = formValues.comments;
        }

        //Now I try insert the Enquiry record
        try{
            insert newEnquiry;
        }
        catch(Exception e){
            System.debug('Exception on Line: ' + e.getLineNumber() + ' : ' + e.getMessage());
            resultList.add('ERROR');
            resultList.add('ERROR! '  + e.getMessage());
            return resultList;
        }

        //If the record is created succesfully then we call the method that will handle the api callout
        sendAPI(newEnquiry.Id);

        //If no errors have occured unitl the point then I add SUCCESS to the resultList
        resultList.add('SUCCESS');

        return resultList;
    }

    @future(callout = true)
    public static void sendAPI(String enquiryId){
        //This method will handle the formatting and collection of data to send the API callout
        Enquiry__c theEnquiry = [SELECT Enquiry_Number__c, First_Name__c, Last_Name__c, Email__c, Phone__c, Country__c, Arrival_Date__c, Departure_Date__c, Holiday_Type__c, Number_of_Adults__c, Number_of_Children__c, Comments__c FROM Enquiry__c WHERE Id =: enquiryId];
        //The dates need to be formatted but only if they aren't null therefore I will create the variables then do the condition
        String[] arrivalArray = new String[]{};
        String[] departureArray = new String[]{};
        
        if(theEnquiry.Arrival_Date__c != null){
            arrivalArray = String.valueOf(theEnquiry.Arrival_Date__c).split(' ');
        }
        else{
            arrivalArray.add('null');
        }

        if(theEnquiry.Departure_Date__c != null){
            departureArray = String.valueOf(theEnquiry.Departure_Date__c).split(' ');
        }
        else{
            departureArray.add('null');
        }

        String requestBody = '{"website_reference_number": "' + theEnquiry.Enquiry_Number__c + '",' +
                            '"first_name": "' + theEnquiry.First_Name__c + '",' +
                            '"last_name": "' + theEnquiry.Last_Name__c + '",' +
                            '"email": "' + theEnquiry.Email__c + '",' +
                            '"contact_number": "' + theEnquiry.Phone__c + '",' +
                            '"country": "' + theEnquiry.Country__c + '",' +
                            '"arrival_date": "' + arrivalArray[0] + '",' +
                            '"departure_date": "' + departureArray[0] + '",' +
                            '"holiday_type": "' + theEnquiry.Holiday_Type__c + '",' +
                            '"adults": "' + theEnquiry.Number_of_Adults__c + '",' +
                            '"children": "' + theEnquiry.Number_of_Children__c + '",' +
                            '"comments": "' + theEnquiry.Comments__c + '",' +
                            '"ed_website": "' + ED_WEBSITE + '",' +
                            '"ed_passkey": "' + ED_PASSKEY + '"}';
        
        System.debug('Request Body: ' + requestBody);

        //Now I create the HTTP request and then the HTTP to send the request
        HttpRequest request = new HttpRequest();
        request.setEndpoint(API_ENDPOINT);
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');
        request.setBody(requestBody);

        Http http = new Http();

        HttpResponse response = http.send(request);

        System.debug('Status Code: ' + response.getStatusCode());
        System.debug('Response Body: ' + response.getBody());

        //I created a field on the Enquiry object to hold the results of the API callout
        if(response.getStatusCode() == 202){
            //This condition means the API callout succeeded 
            //I update the Enquiry record with the results
            Enquiry__c updateEnquiry = new Enquiry__c();
            updateEnquiry.Id = theEnquiry.Id;
            updateEnquiry.API_Callout_Successful__c = true;
            updateEnquiry.API_Response__c = 'Success!';
            update updateEnquiry;
        }
        else{
            //This condition means that the API callout failed
            //I parse the response data in order to get the error message
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            String errorMessage = (String) responseMap.get('message');

            //I update the enquiry with the callout status as well as the error message and all the failed
            //enquiries can be tracked in a Report
            Enquiry__c updateEnquiry = new Enquiry__c();
            updateEnquiry.Id = theEnquiry.Id;
            updateEnquiry.API_Callout_Successful__c = false; //technically it is already false
            updateEnquiry.API_Response__c = errorMessage;
            update updateEnquiry;
        }
    }

    //Custom in code object to help with handling the data (OOP is the best)
    public class FormObject{
        public String firstName { get; set; }
        public String lastName { get; set; }
        public String email { get; set; }
        public String phone { get; set; }
        public String country { get; set; }
        public String holidayType { get; set; }
        public Date arrivalDate { get; set; }
        public Date departureDate { get; set; }
        public Integer numOfAdults { get; set; }
        public Integer numOfKids { get; set; }
        public String enquiryType { get; set; }
        public String comments { get; set; }
    }
}