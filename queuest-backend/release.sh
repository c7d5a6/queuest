#!/bin/bash

ssh foundry@foundry.owlbeardm.com "cd /home/foundry/queuest && git pull"
# ssh foundry@foundry.owlbeardm.com ". /home/foundry/.nvm/install.sh && cd /home/foundry/queuest/queuest-backend && nvm use && /home/foundry/.nvm/versions/node/v18.16.0/bin/npm --version"
ssh foundry@foundry.owlbeardm.com ". /home/foundry/.nvm/install.sh && \
                                   cd /home/foundry/queuest/queuest-backend && \
                                   nvm use ; \
                                   npm --version && \
                                   npm ci && \
                                   npm run build && \
                                   pm2 restart queuest && \
                                   pm2 log --lines 30"