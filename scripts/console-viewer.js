// console-viewer.js
// Opens the correct AWS Console page in your browser for each Terraform file.
// Uses your existing browser session — you must already be logged in to AWS.
//
// Usage:
//   node console-viewer.js <step>
//
// Examples:
//   node console-viewer.js vpc
//   node console-viewer.js subnets
//   node console-viewer.js route_tables
//   node console-viewer.js security
//   node console-viewer.js elb
//   node console-viewer.js ec2
//   node console-viewer.js rds
//   node console-viewer.js s3

const { chromium } = require('playwright');

const REGION = 'eu-central-1';

// Each step maps to the exact AWS Console URL for that resource
const STEPS = {
  vpc: {
    label: 'VPC + Internet Gateway',
    pages: [
      {
        title: 'Your VPCs',
        url: `https://console.aws.amazon.com/vpc/home?region=${REGION}#vpcs:`,
        description: 'You will see your VPC listed here — look for "3tier-vpc" after apply',
      },
      {
        title: 'Internet Gateways',
        url: `https://console.aws.amazon.com/vpc/home?region=${REGION}#igws:`,
        description: 'The IGW "3tier-igw" will appear here and show "Attached" state',
      },
    ],
  },

  subnets: {
    label: 'Subnets (all 6)',
    pages: [
      {
        title: 'Subnets',
        url: `https://console.aws.amazon.com/vpc/home?region=${REGION}#subnets:`,
        description: 'You will see 6 subnets: web-az1, web-az2, app-az1, app-az2, db-az1, db-az2',
      },
    ],
  },

  route_tables: {
    label: 'Route Tables',
    pages: [
      {
        title: 'Route Tables',
        url: `https://console.aws.amazon.com/vpc/home?region=${REGION}#routetables:`,
        description: 'Look for "3tier-public-rt" — click it, then "Routes" tab to see the IGW route',
      },
    ],
  },

  security: {
    label: 'Security Groups',
    pages: [
      {
        title: 'Security Groups',
        url: `https://console.aws.amazon.com/vpc/home?region=${REGION}#securityGroups:`,
        description: 'You will see 3 SGs: 3tier-elb-sg, 3tier-web-sg, 3tier-app-sg, 3tier-db-sg',
      },
    ],
  },

  sg: {
    label: 'Security Groups',
    pages: [
      {
        title: 'Security Groups',
        url: `https://console.aws.amazon.com/vpc/home?region=${REGION}#securityGroups:`,
        description: 'Look for cli-3tier-elb-sg, web-sg, app-sg, db-sg',
      },
    ],
  },

  elb: {
    label: 'Elastic Load Balancer',
    pages: [
      {
        title: 'Load Balancers',
        url: `https://console.aws.amazon.com/ec2/home?region=${REGION}#LoadBalancers:`,
        description: 'Look for "3tier-elb" — click it to see listeners and target groups',
      },
      {
        title: 'Target Groups',
        url: `https://console.aws.amazon.com/ec2/home?region=${REGION}#TargetGroups:`,
        description: 'The target group "3tier-web-tg" should show healthy targets after EC2s are up',
      },
    ],
  },

  ec2: {
    label: 'EC2 Instances + Auto Scaling',
    pages: [
      {
        title: 'EC2 Instances',
        url: `https://console.aws.amazon.com/ec2/home?region=${REGION}#Instances:`,
        description: 'Web and app tier EC2s appear here — look for "3tier-web" and "3tier-app"',
      },
      {
        title: 'Auto Scaling Groups',
        url: `https://console.aws.amazon.com/ec2/home?region=${REGION}#AutoScalingGroups:`,
        description: 'Two ASGs: "3tier-web-asg" and "3tier-app-asg" — each starts with 1 instance',
      },
      {
        title: 'Launch Templates',
        url: `https://console.aws.amazon.com/ec2/home?region=${REGION}#LaunchTemplates:`,
        description: 'The launch template defines the AMI and instance type used by the ASG',
      },
    ],
  },

  ec2: {
    label: 'EC2 Instances',
    pages: [
      {
        title: 'EC2 Instances',
        url: `https://console.aws.amazon.com/ec2/home?region=${REGION}#Instances:`,
        description: 'Look for cli-3tier-web-ec2 (public IP) and cli-3tier-app-ec2 (private)',
      },
    ],
  },

  rds: {
    label: 'RDS Database',
    pages: [
      {
        title: 'RDS Databases',
        url: `https://console.aws.amazon.com/rds/home?region=${REGION}#databases:`,
        description: 'Look for "3tier-db" — primary in AZ 1A, replica in AZ 1B',
      },
      {
        title: 'RDS Subnet Groups',
        url: `https://console.aws.amazon.com/rds/home?region=${REGION}#db-subnet-groups-list:`,
        description: 'The subnet group "3tier-db-subnet-group" links RDS to your private DB subnets',
      },
    ],
  },

  s3: {
    label: 'S3 Bucket + VPC Endpoint',
    pages: [
      {
        title: 'S3 Buckets',
        url: `https://s3.console.aws.amazon.com/s3/buckets?region=${REGION}`,
        description: 'Your bucket appears here — public access should show as "Blocked"',
      },
      {
        title: 'VPC Endpoints',
        url: `https://console.aws.amazon.com/vpc/home?region=${REGION}#Endpoints:`,
        description: 'The Gateway Endpoint for S3 — keeps S3 traffic inside AWS, no internet needed',
      },
    ],
  },
};

async function openConsolePages(step) {
  const config = STEPS[step];

  if (!config) {
    console.log('\nUnknown step. Available steps:');
    Object.keys(STEPS).forEach(s => console.log(`  ${s} — ${STEPS[s].label}`));
    process.exit(1);
  }

  console.log(`\nOpening AWS Console for: ${config.label}\n`);

  let browser;
  let context;

  try {
    // Try to connect to your already-running Chrome via remote debugging port 9222
    browser = await chromium.connectOverCDP('http://localhost:9222');
    context = browser.contexts()[0]; // use the existing window/session
    console.log('Connected to your running Chrome — using your existing AWS session.\n');
  } catch (e) {
    // Chrome is not running with debug port — fall back to launching a new instance
    console.log('Could not connect to running Chrome. Launching a new window...');
    console.log('Tip: next time start Chrome with: google-chrome --remote-debugging-port=9222\n');
    context = await chromium.launchPersistentContext(
      '/tmp/chrome-izi', // copied profile with your cookies
      {
        headless: false,
        channel: 'chrome',
        args: ['--start-maximized'],
      }
    );
  }

  // Open each page as a new tab in whatever context we have
  for (const page of config.pages) {
    const tab = await context.newPage();
    console.log(`Opening: ${page.title}`);
    console.log(`  URL: ${page.url}`);
    console.log(`  What to look for: ${page.description}\n`);
    await tab.goto(page.url);
    await tab.waitForLoadState('domcontentloaded');
  }

  console.log('Done — tabs are open in your browser.\n');

  // If we launched a new browser (not connected), keep alive until closed
  if (!browser) {
    await new Promise(resolve => context.on('close', resolve));
    await context.close();
  }
}

// Read the step argument from the command line
const step = process.argv[2];

if (!step) {
  console.log('\nUsage: node console-viewer.js <step>');
  console.log('\nAvailable steps:');
  Object.keys(STEPS).forEach(s => console.log(`  ${s} — ${STEPS[s].label}`));
  process.exit(1);
}

openConsolePages(step).catch(err => {
  console.error('Error:', err.message);
  process.exit(1);
});
