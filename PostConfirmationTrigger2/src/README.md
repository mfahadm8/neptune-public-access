It appears that the `aws-sdk` package is not included in your Lambda function deployment package. To fix this, you need to include the necessary dependencies in your deployment package. Here’s how you can do it:

### Step-by-Step Instructions

1. **Set Up Your Project Directory**

   Create a new directory for your Lambda function, and navigate to it:
   ```bash
   mkdir lambda-post-confirmation
   cd lambda-post-confirmation
   ```

2. **Initialize a Node.js Project**

   Initialize a new Node.js project, which will create a `package.json` file:
   ```bash
   npm init -y
   ```

3. **Install Required Dependencies**

   Install the `aws-sdk` and `gremlin` packages:
   ```bash
   npm install aws-sdk gremlin
   ```

4. **Create Your Lambda Function File**

   Create a file named `index.js` and add your Lambda function code:
   ```javascript
   import AWS from 'aws-sdk';
   import { DriverRemoteConnection } from 'gremlin';

   const NEPTUNE_ENDPOINT = process.env.NEPTUNE_ENDPOINT;

   export const handler = async (event) => {
       console.log('Post Confirmation Event:', JSON.stringify(event, null, 2));
       
       const userAttributes = event.request.userAttributes;
       const userId = userAttributes.sub;
       const email = userAttributes.email;
       const phoneNumber = userAttributes.phone_number;
       const userType = userAttributes['custom:user_type'];

       const gremlinClient = new DriverRemoteConnection(`wss://${NEPTUNE_ENDPOINT}:8182/gremlin`);
       const graph = new gremlin.structure.Graph();
       const g = graph.traversal().withRemote(gremlinClient);

       try {
           await g.addV('User')
               .property('id', userId)
               .property('email', email)
               .property('phoneNumber', phoneNumber)
               .property('userType', userType)
               .next();
           
           console.log('User attributes written to Neptune:', userId);
       } catch (err) {
           console.error('Error writing to Neptune:', err);
           throw err;
       } finally {
           gremlinClient.close();
       }

       return event;
   };
   ```

5. **Create a Deployment Package**

   Zip the contents of your project directory to create the deployment package:
   ```bash
   zip -r lambda-post-confirmation.zip .
   ```

6. **Upload the Deployment Package to AWS Lambda**

   Use the AWS Management Console or the AWS CLI to create or update your Lambda function with the deployment package.

   Using AWS CLI:
   ```bash
   aws lambda update-function-code --function-name your-function-name --zip-file fileb://lambda-post-confirmation.zip
   ```

### Ensure the Lambda Function Configuration

1. **Set Runtime**: Ensure that the Lambda function runtime is set to Node.js 14.x or higher.
2. **Set Environment Variables**: In the AWS Management Console, go to the Configuration tab of your Lambda function and set the `NEPTUNE_ENDPOINT` environment variable.

By following these steps, you should be able to include the necessary dependencies in your Lambda deployment package and avoid the "Cannot find package 'aws-sdk'" error.