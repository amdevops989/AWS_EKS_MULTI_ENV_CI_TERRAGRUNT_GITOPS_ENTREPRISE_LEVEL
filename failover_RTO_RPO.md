validation for a Pilot Light setup. Automated failover testing will give you exact metrics on your RTO (Recovery Time Objective) and RPO (Recovery Point Objective).


Step 1: Clear the Current Apex A Record
Before Route 53 will let you create failover records, you need to remove the old simple record sitting on the domain.

In your Hosted Zone (vanguardyouth.store) record list, check the box next to the vanguardyouth.store A record (the one currently showing Simple).

Click the Delete record button at the top.

Step 2: Create the Primary Failover Record (Dev / us-east-1)
Click Create record.

Record name: Leave blank (this targets the main domain vanguardyouth.store).

Record type: Keep as A.

Alias: Toggle to On.

Route traffic to: Select Alias to Network Load Balancer.

Region: Select us-east-1 (N. Virginia).

Load balancer: Choose your Dev load balancer (a5852a52a...).

Routing policy: Select Failover.

Failover record type: Select Primary.

Health check ID - optional: Select your prod-hc health check (75a3f884...).

Evaluate target health: Toggle to Yes.

Record ID: Type dev-us-east-1-primary.

Click Add another record (do not save yet).

Step 3: Create the Secondary Failover Record (DR / us-west-1)
In the second record form that opens on screen:

Record name: Leave blank.

Record type: Keep as A.

Alias: Toggle to On.

Route traffic to: Select Alias to Network Load Balancer.

Region: Select us-west-1 (N. California).

Load balancer: Choose your DR load balancer (a218135cf...).

Routing policy: Select Failover.

Failover record type: Select Secondary.

Health check ID - optional: Leave this completely EMPTY / None.

Evaluate target health: Toggle to Yes.

Record ID: Type dr-us-west-1-secondary.

Click Create records at the bottom right.

Step 4: How to Know It Worked
Once saved, look at your main Route 53 records table. You should now see two vanguardyouth.store A records:

One labeled Failover | Primary pointing to us-east-1 with your health check attached.

One labeled Failover | Secondary pointing to us-west-1 with no health check attached.