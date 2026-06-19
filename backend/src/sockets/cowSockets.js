const { getDB } = require("../config/database");

const initCowSockets = (wss) => {
    
    // 1. Handle incoming user connections
    wss.on('connection', async (ws) => {
        console.log('A user connected via pure WebSocket');

        try {
            const db = getDB();
            const cows = await db.collection("cows").find({}).toArray();
            
            // CHG: Must stringify payloads before sending over pure streams
            const initialPayload = JSON.stringify({ event: 'initialCows', data: cows });
            ws.send(initialPayload);
        } catch (err) {
            console.error("Error fetching cows for socket connection:", err);
        }

        ws.on('close', () => {
            console.log('A user disconnected from WebSocket');
        });
    });

    // 2. Watch MongoDB and broadcast changes
    try {
        const db = getDB();
        const cowCollection = db.collection("cows");
        const changeStream = cowCollection.watch();

        changeStream.on('change', (change) => {
            if (change.operationType === 'insert') {
                const broadcastPayload = JSON.stringify({ event: 'newCow', data: change.fullDocument });
                wss.clients.forEach(c => c.readyState === 1 && c.send(broadcastPayload));
            } 
            else if (change.operationType === 'update' || change.operationType === 'replace') {
                // Broadcast edited changes
                const updatedCow = change.fullDocument || { _id: change.documentKey._id, ...change.updateDescription.updatedFields };
                const broadcastPayload = JSON.stringify({ event: 'updateCow', data: updatedCow });
                wss.clients.forEach(c => c.readyState === 1 && c.send(broadcastPayload));
            } 
            else if (change.operationType === 'delete') {
                // Broadcast deletion event by passing the targeted ID
                const broadcastPayload = JSON.stringify({ event: 'deleteCow', data: { _id: change.documentKey._id } });
                wss.clients.forEach(c => c.readyState === 1 && c.send(broadcastPayload));
            }
        });
    } catch (err) {
        console.error("Error initializing cow sockets:", err);
    }
}

module.exports = { initCowSockets };