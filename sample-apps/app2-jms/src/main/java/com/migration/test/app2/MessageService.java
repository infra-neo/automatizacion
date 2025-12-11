package com.migration.test.app2;

import javax.annotation.Resource;
import javax.ejb.Stateless;
import javax.jms.Connection;
import javax.jms.ConnectionFactory;
import javax.jms.MessageProducer;
import javax.jms.Queue;
import javax.jms.Session;
import javax.jms.TextMessage;

@Stateless
public class MessageService {
    
    @Resource(mappedName = "java:/ConnectionFactory")
    private ConnectionFactory connectionFactory;
    
    @Resource(mappedName = "java:/jms/queue/TestQueue")
    private Queue queue;
    
    public void sendMessage(String messageText) throws Exception {
        Connection connection = null;
        Session session = null;
        
        try {
            connection = connectionFactory.createConnection();
            session = connection.createSession(false, Session.AUTO_ACKNOWLEDGE);
            MessageProducer producer = session.createProducer(queue);
            
            TextMessage message = session.createTextMessage(messageText);
            producer.send(message);
            
            System.out.println("Message sent: " + messageText);
        } finally {
            if (session != null) session.close();
            if (connection != null) connection.close();
        }
    }
}
