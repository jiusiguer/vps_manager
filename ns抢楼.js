// ==UserScript==
// @name         NodeSeek Auto Reply
// @namespace    http://tampermonkey.net/
// @version      0.1
// @description  自动监测并回复NodeSeek论坛特定用户的帖子
// @author       Your name
// @match        https://www.nodeseek.com/*
// @grant        none
// @run-at       document-end
// ==/UserScript==

(function() {
    'use strict';

    // 配置项
    const config = {
        targetAuthor: 'CLAWCLOUD-VPS',
        replyContent: '占楼',
        checkInterval: 2000,
        refreshInterval: 5000,
        isRunning: true, // 控制脚本运行状态
    };

    // 创建控制面板
    function createControlPanel() {
        const panel = document.createElement('div');
        panel.innerHTML = `
            <div id="script-control-panel" style="
                position: fixed;
                top: 20px;
                right: 20px;
                background: rgba(0, 0, 0, 0.8);
                padding: 15px;
                border-radius: 8px;
                z-index: 9999;
                color: white;
                font-size: 14px;
                min-width: 200px;
            ">
                <div style="margin-bottom: 10px; font-weight: bold; border-bottom: 1px solid #666; padding-bottom: 5px;">
                    NodeSeek 自动回复控制面板
                </div>
                <div style="margin-bottom: 10px;">
                    状态: <span id="script-status" style="color: #00ff00;">运行中</span>
                </div>
                <div style="margin-bottom: 10px;">
                    <button id="toggle-script" style="
                        background: #666;
                        border: none;
                        color: white;
                        padding: 5px 10px;
                        border-radius: 4px;
                        cursor: pointer;
                    ">暂停脚本</button>
                </div>
                <div style="margin-bottom: 10px;">
                    检查间隔(秒): 
                    <input type="number" id="check-interval" value="${config.checkInterval/1000}" min="1" max="60" style="
                        width: 50px;
                        background: #333;
                        border: 1px solid #666;
                        color: white;
                        padding: 2px;
                    ">
                </div>
                <div style="margin-bottom: 10px;">
                    刷新间隔(秒): 
                    <input type="number" id="refresh-interval" value="${config.refreshInterval/1000}" min="1" max="60" style="
                        width: 50px;
                        background: #333;
                        border: 1px solid #666;
                        color: white;
                        padding: 2px;
                    ">
                </div>
                <div id="script-log" style="
                    margin-top: 10px;
                    padding: 5px;
                    background: #333;
                    border-radius: 4px;
                    max-height: 150px;
                    overflow-y: auto;
                    font-size: 12px;
                ">
                    <div>日志记录:</div>
                </div>
            </div>
        `;
        document.body.appendChild(panel);

        // 添加事件监听
        setupControlPanelEvents();
    }

    // 设置控制面板事件
    function setupControlPanelEvents() {
        const toggleBtn = document.getElementById('toggle-script');
        const statusSpan = document.getElementById('script-status');
        const checkIntervalInput = document.getElementById('check-interval');
        const refreshIntervalInput = document.getElementById('refresh-interval');

        toggleBtn.addEventListener('click', () => {
            config.isRunning = !config.isRunning;
            toggleBtn.textContent = config.isRunning ? '暂停脚本' : '启动脚本';
            statusSpan.textContent = config.isRunning ? '运行中' : '已暂停';
            statusSpan.style.color = config.isRunning ? '#00ff00' : '#ff0000';
            addLog(config.isRunning ? '脚本已启动' : '脚本已暂停');
        });

        checkIntervalInput.addEventListener('change', () => {
            config.checkInterval = checkIntervalInput.value * 1000;
            addLog(`检查间隔已更新为 ${checkIntervalInput.value} 秒`);
        });

        refreshIntervalInput.addEventListener('change', () => {
            config.refreshInterval = refreshIntervalInput.value * 1000;
            addLog(`刷新间隔已更新为 ${refreshIntervalInput.value} 秒`);
        });
    }

    // 添加日志
    function addLog(message) {
        const logDiv = document.getElementById('script-log');
        const time = new Date().toLocaleTimeString();
        logDiv.innerHTML += `<div>[${time}] ${message}</div>`;
        logDiv.scrollTop = logDiv.scrollHeight;
    }

    // 检查是否在主页
    function isHomePage() {
        return window.location.pathname === '/';
    }

    // 检查是否在帖子页面
    function isPostPage() {
        return window.location.pathname.startsWith('/post-');
    }

    // 监控主页帖子
    function checkPosts() {
        if (!config.isRunning) return;
        
        addLog('检查帖子中...');
        const posts = document.querySelectorAll('.post-list-item');
        if (!posts || posts.length < 9) {
            addLog('帖子数量不足9个，等待下次检查');
            return;
        }

        // 检查第4到第9个帖子
        for (let i = 3; i <= 8; i++) {
            const post = posts[i];
            const authorElement = post.querySelector('.info-item.info-author');
            if (!authorElement) continue;

            const author = authorElement.textContent.trim();
            addLog(`检查第${i+1}个帖子，作者: ${author}`);
            
            if (author === config.targetAuthor) {
                // 检查评论数
                const commentsElement = post.querySelector('.info-item.info-comments-count');
                if (commentsElement) {
                    const commentsCount = parseInt(commentsElement.textContent.trim());
                    addLog(`帖子评论数: ${commentsCount}`);
                    
                    if (commentsCount >= 100) {
                        addLog('评论数超过100，跳过此帖子');
                        continue;
                    }
                    
                    // 评论数符合要求，点击进入
                    addLog('找到目标帖子且评论数小于100！');
                    const link = post.querySelector('a[href^="/post-"]');
                    if (link) {
                        link.click();
                        return;
                    }
                }
            }
        }
    }

    // 在帖子页面自动回复
    function autoReply() {
        // 检查是否已经回复过这个帖子
        const currentPostId = window.location.pathname.split('-')[1];
        if (localStorage.getItem(`replied_${currentPostId}`)) {
            addLog('该帖子已经回复过，避免重复回复');
            return;
        }

        // 找到编辑器
        const editor = document.querySelector('.CodeMirror');
        if (!editor) return;

        // 设置回复内容
        const cmInstance = editor.CodeMirror;
        if (cmInstance) {
            cmInstance.setValue(config.replyContent);
        }

        // 点击发送按钮
        const submitButton = document.querySelector('button.submit.btn');
        if (submitButton) {
            // 标记该帖子已回复，防止重复提交
            localStorage.setItem(`replied_${currentPostId}`, 'true');
            
            submitButton.click();
            
            // 添加回复成功的处理
            setTimeout(() => {
                config.isRunning = false; // 停止脚本运行
                
                // 更新控制面板状态
                const toggleBtn = document.getElementById('toggle-script');
                const statusSpan = document.getElementById('script-status');
                if (toggleBtn && statusSpan) {
                    toggleBtn.textContent = '启动脚本';
                    statusSpan.textContent = '已完成';
                    statusSpan.style.color = '#00ff00';
                }
                
                addLog('✅ 回复成功，脚本已自动停止运行');
                
                // 将成功状态保存到localStorage
                localStorage.setItem('replyCompleted', 'true');
                
                // 2秒后返回主页
                setTimeout(() => {
                    window.location.href = 'https://www.nodeseek.com/';
                }, 2000);
            }, 1000); // 等待1秒确保回复成功
        }
    }

    // 主函数
    function main() {
        // 检查是否已经完成回复
        if (localStorage.getItem('replyCompleted') === 'true') {
            config.isRunning = false;
            addLog('已经完成回复任务，脚本停止运行');
            return;
        }

        createControlPanel();
        
        if (isHomePage()) {
            addLog('脚本在主页启动');
            // 先执行一次检查
            checkPosts();
            
            // 只设置页面刷新定时器，每次刷新后会自动执行检查
            if (config.isRunning) {
                setTimeout(() => {
                    if (config.isRunning) {
                        addLog('准备刷新页面...');
                        window.location.reload(true);
                    }
                }, config.refreshInterval);
            }
        } else if (isPostPage()) {
            addLog('脚本在帖子页面启动');
            setTimeout(autoReply, 1000);
        }
    }

    // 启动脚本
    main();
})(); 
