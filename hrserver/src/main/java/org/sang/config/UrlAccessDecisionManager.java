package org.sang.config;

import org.apache.commons.collections4.CollectionUtils;
import org.springframework.security.access.AccessDecisionManager;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.access.ConfigAttribute;
import org.springframework.security.authentication.AnonymousAuthenticationToken;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.AuthenticationException;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.stereotype.Component;

import java.util.Collection;
import java.util.Iterator;
import java.util.List;
import java.util.stream.Collectors;

/**
 * Created by sang on 2017/12/28.
 */
@Component
public class UrlAccessDecisionManager implements AccessDecisionManager {
    @Override
    public void decide(Authentication auth, Object o, Collection<ConfigAttribute> cas){

        /**
         * 当前请求需要的角色
         */
        List<String> needRoles = cas.stream().map(ConfigAttribute::getAttribute).collect(Collectors.toList());
        if (needRoles.contains("ROLE_LOGIN")){
            if (auth instanceof AnonymousAuthenticationToken) {
                throw new BadCredentialsException("未登录");
            } else {
                return;
            }
        }
        /**
         * 当前用户拥有的角色
         */
        List<String> userRoles = auth.getAuthorities().stream().map(GrantedAuthority::getAuthority).collect(Collectors.toList());

        /**
         * 1、如果需要角色 b c，用户只需要满足拥有其中一个即可,取交集
         */
        userRoles.retainAll(needRoles);
        if (CollectionUtils.isNotEmpty(userRoles)){
                return;
        }
        /**
         * 2、如果需要角色 b c，则用户必须同时拥有这两个角色
         */
//        if (userRoles.containsAll(needRoles)){
//            return;
//        }








//        Iterator<ConfigAttribute> iterator = cas.iterator();
//        while (iterator.hasNext()) {
//            ConfigAttribute ca = iterator.next();
//            //当前请求需要的权限
//            String needRole = ca.getAttribute();
//            if ("ROLE_LOGIN".equals(needRole)) {
//                if (auth instanceof AnonymousAuthenticationToken) {
//                    throw new BadCredentialsException("未登录");
//                } else
//                    return;
//            }
//            //当前用户所具有的权限
//            Collection<? extends GrantedAuthority> authorities = auth.getAuthorities();
//            for (GrantedAuthority authority : authorities) {
//                if (authority.getAuthority().equals(needRole)) {
//                    return;
//                }
//            }
//        }
        throw new AccessDeniedException("权限不足!");
    }
    @Override
    public boolean supports(ConfigAttribute configAttribute) {
        return true;
    }
    @Override
    public boolean supports(Class<?> aClass) {
        return true;
    }
}
