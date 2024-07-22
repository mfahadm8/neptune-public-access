const AWS = require('aws-sdk');
const gremlin = require('gremlin');
const { DriverRemoteConnection } = gremlin.driver;
const { structure } = gremlin;

const NEPTUNE_ENDPOINT = process.env.NEPTUNE_ENDPOINT;

exports.handler = async (event) => {
    console.log('Post Confirmation Event:', JSON.stringify(event, null, 2));
    console.log('NEPTUNE_ENDPOINT:', NEPTUNE_ENDPOINT);

    const userAttributes = event.request.userAttributes;
    const userId = userAttributes.sub;
    const email = userAttributes.email;
    const phoneNumber = userAttributes.phone_number;
    const userType = userAttributes['custom:user_type'];
    console.log('attributes loaded 1');

    const gremlinClient = new DriverRemoteConnection(`wss://${NEPTUNE_ENDPOINT}:8182/gremlin`);
    console.log('attributes loaded 2');
    const graph = new structure.Graph();
    console.log('attributes loaded 3');
    const g = graph.traversal().withRemote(gremlinClient);
    console.log('attributes loaded 4');

   

    console.log('Connection successful. started the process......');

    try {
        console.log('Attempting to run a simple query.');
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
