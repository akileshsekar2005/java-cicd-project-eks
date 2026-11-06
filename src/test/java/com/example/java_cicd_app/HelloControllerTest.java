package com.example.java_cicd_app;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;

class HelloControllerTest {

    @Test
    void testHome() {

        HelloController controller =
                new HelloController();

        String result = controller.home();

        assertEquals(
            "Hello, DevOps! Version 1.0",
            result
        );
    }

    @Test
    void testHealth() {

        HelloController controller =
                new HelloController();

        String result = controller.health();

        assertEquals(
            "{\"status\":\"UP\"}",
            result
        );
    }
}