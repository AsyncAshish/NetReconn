this folder is where all the scan reports get saved.

every time you run NetRecon.sh it automatically creates a report file here
with the target name and timestamp in the filename so you can keep track
of all your scans without losing anything.

example filename: recon_example.com_2024-01-15_14-30-22.txt

the report includes everything the tool found during the scan:
- dns records
- whois info
- open ports
- http header analysis
- ip geolocation
- subdomains

this folder is empty by default. reports will show up here after your first scan.
