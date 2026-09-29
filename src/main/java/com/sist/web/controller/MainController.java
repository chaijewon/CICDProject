package com.sist.web.controller;

import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;

@Controller
// 컨트롤러

public class MainController {
    @GetMapping("/")
    public String main_main(Model model) {
    	model.addAttribute("msg", "Hello CI/CD!!!");
    	return "main";
    }
    
}
