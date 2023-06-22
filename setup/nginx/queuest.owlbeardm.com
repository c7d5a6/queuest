# This goes in a file within /etc/nginx/sites-available/. By convention,
# the filename would be either "your.domain.com" or "foundryvtt", but it
# really does not matter as long as it's unique and descriptive for you.

# Define Server
server {

    # Enter your fully qualified domain name or leave blank
    server_name             api.queuest.c7d5a6.com;

    # Listen on port 80 without SSL certificates
    listen                  443 ssl;
    ssl_certificate         "/etc/letsencrypt/live/api.queuest.c7d5a6.com/fullchain.pem";
    ssl_certificate_key     "/etc/letsencrypt/live/api.queuest.c7d5a6.com/privkey.pem";
#    listen                  3001;


    # Sets the Max Upload size to 300 MB
    client_max_body_size 300M;

    # Proxy Requests to Foundry VTT
    location / {

        # Set proxy headers
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # These are important to support WebSockets
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "Upgrade";

        # Make sure to set your Foundry VTT port number
        proxy_pass http://127.0.0.1:3002$request_uri;
    }
}

server {
    if ($host = api.queuest.c7d5a6.com) {
        return 301 https://$host$request_uri;
    }

    listen 80;
        listen [::]:80;

    server_name api.queuest.c7d5a6.com;
    return 404;
}