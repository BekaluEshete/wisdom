## Activity Diagram for eChallan Issuance

This diagram illustrates the workflow for an Officer issuing an eChallan, including the critical steps of verification, evidence collection, and system synchronization.

\`\`\`mermaid
%% Activity Diagram
activityDiagram
start
:Officer stops vehicle;
:Officer requests DL/RC;

partition "Officer App (Offline/Online)" {
:Search Vehicle/DL details (Online/Cache);
if (Details Found?) then (Yes)
:Verify details;
else (No)
:Record details manually;
endif

    :Select Violation Type;
    :Capture Photo/Video Evidence;
    :Record GPS Location;
    :Generate eChallan Record;

    if (Online?) then (Yes)
      :Send Challan to Backend Service;
      :Receive Confirmation;
    else (No)
      :Store Challan in Local Queue;
      :Display Offline Confirmation;
    endif

}

partition "Backend Service" {
:Validate Challan Data;
:Persist Challan to Database;
:Update Vehicle/DL Status (if necessary);
:Trigger Notification Service;
}

partition "Notification Service" {
:Retrieve Owner Contact Info;
:Send SMS/Push/Email Notification;
}

:Officer informs Citizen of Challan;

if (Offline Challan?) then (Yes)
:Officer App syncs queue when online;
else (No)
endif

stop
\`\`\`
