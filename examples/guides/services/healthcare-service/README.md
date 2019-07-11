# Ballerina Healthcare Service 

## __healthcare_service.bal__
The main service through which all the healthcare calls go through.

Base path of the healthcare service : `/healthcare`

Holds a record called `healthcareDAO` which contains all the __doctor lists__ from each hospital, the available __categories__ and __payments__. It also holds a map of all the __appointments__ that are placed 

### Service Endpoints
- Get Doctors
    - [`GET`] - path: `/{category}`

- Get Appointment
    - [`GET`] - path: `/appointments/{appointmentId}`

- Get Appointment Validity time
    - [`GET`] - path: `/appointments/validity/{appointmentId}`

- Delete Appointment
    - [`DELETE`] - path: `/appointments/{appointmentId}`

- Settle Payment
    - [`POST`] - path: `/payments`

- Get Payment Details
    - [`GET`] - path: `/payments/payment/{paymentId}`

- Add New Doctor
    - [`POST`] - path: `/admin/newdoctor`

---

## __hopital_service.bal__
Contains the common functions that each hospital service uses. 

Base path of each hospital service : `/{hostpital_name}/categories`

### Service Endpoints

- Reserve Appointment
    - Requires Hospital DAO record and category
    - [`POST`] - path : `/{category}/reserve` 

- Get Appointment
    - Requires Appointment number
    - [`GET`] - path: `/appointments/{appointmentId}`

- Check channeling fee 
    - Requires Appointment number
    - [`GET`] - path: `/appointments/{appointmentId}/fee`

- Update patient record
    - Requires Hospital DAO record
    - [`POST`] = path: `/patient/updaterecord`

- Get patient record
    - Requires Hospital DAO record and Patient ssn
    - [`GET`] - path: `/patient/{ssn}/getrecord`

- Is eligible for discount
    - Requires Appointment number
    - [`GET`] - path: `/patient/appointment/{appointmentId}/discount`

- Add new Doctor
    - Requires Hospital DAO
    - [`POST`] - path: `/admin/doctor/newdoctor`


### Hospitals : Clemency, GrandOak, PineValley, WillowGardens
Each of these hospitals has a basepath defined with the hospital name

Path names defined are : `["clemency", "grandoaks", "pinevalley", "willowgardens"]`

- __daos:Doctor__ : Details of doctors in the particular hospital stored in a list
- __daos:Hospital__ : Details of the hospital, including doctorsList, categories, patientMap and patientRecordMap

Known categories defined are : `["surgery", "cardiology", "gynaecology", "ent", "paediatric"]`

---
### Utils.bal
Contains the common utility functions that hostpital_service.bal uses 

- Send Response

- Contains String Element

- Contains In-patient record map

- Convert JSON to String Array

- Create new Payment entry

- Make new appointment

- Check for discounts

- Check Discount Eligibility

- Check Appointment Id 

