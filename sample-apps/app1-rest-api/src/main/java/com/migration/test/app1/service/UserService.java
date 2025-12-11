package com.migration.test.app1.service;

import com.migration.test.app1.model.User;
import java.util.List;
import javax.ejb.Stateless;
import javax.persistence.EntityManager;
import javax.persistence.PersistenceContext;

@Stateless
public class UserService {
    
    @PersistenceContext(unitName = "app1PU")
    private EntityManager em;
    
    public User createUser(User user) {
        em.persist(user);
        return user;
    }
    
    public User findUserById(Long id) {
        return em.find(User.class, id);
    }
    
    public List<User> findAllUsers() {
        return em.createQuery("SELECT u FROM User u", User.class)
                 .getResultList();
    }
    
    public User updateUser(User user) {
        return em.merge(user);
    }
    
    public void deleteUser(Long id) {
        User user = findUserById(id);
        if (user != null) {
            em.remove(user);
        }
    }
    
    public User findByUsername(String username) {
        List<User> users = em.createQuery(
            "SELECT u FROM User u WHERE u.username = :username", User.class)
            .setParameter("username", username)
            .getResultList();
        return users.isEmpty() ? null : users.get(0);
    }
}
