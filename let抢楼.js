// ==UserScript==
// @name         LowEndTalk Auto Reply
// @namespace    http://tampermonkey.net/
// @version      0.1
// @description  自动监测并回复LowEndTalk论坛特定用户的帖子
// @author       Your name
// @match        https://lowendtalk.com/*
// @grant        none
// @run-at       document-end
// ==/UserScript==

(function() {
    'use strict';

    // 配置项
    const config = {
        targetAuthor: 'CLAWCLOUD',
        replyContent: 'first',
        checkInterval: 3000,  // 3秒检查一次
        refreshInterval: 3000, // 3秒刷新一次
        isRunning: true,
        debug: true,  // 开启调试模式
        // 添加统计数据
        stats: {
            pageRefreshCount: 0,
            repliedPosts: 0,
            startTime: new Date(),
            lastCheckTime: null
        },
        // 添加已知帖子ID列表
        knownDiscussionIds: [
            "202026", // 添加新的已知帖子
            "201696",
            "200813",
            "200662",
            "200021"
        ],
        logConfig: {
            maxLogs: 200,  // 最多保存200条日志
            key: 'letAutoReplyLogs'  // localStorage中存储日志的key
        }
    };

    // 添加状态管理函数
    const scriptState = {
        // 初始化状态
        init() {
            const savedState = localStorage.getItem('letAutoReplyState');
            if (savedState) {
                const state = JSON.parse(savedState);
                config.stats = state.stats;
                config.isRunning = state.isRunning;
                // 如果脚本是第一次运行，设置开始时间
                if (!config.stats.startTime) {
                    config.stats.startTime = new Date().getTime();
                }
            } else {
                config.stats = {
                    pageRefreshCount: 0,
                    repliedPosts: 0,
                    startTime: new Date().getTime(),
                    lastCheckTime: null
                };
            }
            this.saveState();
        },

        // 保存状态
        saveState() {
            const state = {
                stats: config.stats,
                isRunning: config.isRunning
            };
            localStorage.setItem('letAutoReplyState', JSON.stringify(state));
        },

        // 更新统计数据
        updateStats(key, value) {
            config.stats[key] = value;
            this.saveState();
        },

        // 获取保存的日志
        getLogs() {
            const savedLogs = localStorage.getItem(config.logConfig.key);
            return savedLogs ? JSON.parse(savedLogs) : [];
        },

        // 保存日志
        saveLogs(logs) {
            // 只保留最近的200条日志
            const recentLogs = logs.slice(-config.logConfig.maxLogs);
            localStorage.setItem(config.logConfig.key, JSON.stringify(recentLogs));
        },

        // 添加新日志
        addLog(logEntry) {
            const logs = this.getLogs();
            logs.push(logEntry);
            this.saveLogs(logs);
        },

        // 清除所有日志
        clearLogs() {
            localStorage.removeItem(config.logConfig.key);
        },

        // 重置所有状态
        reset() {
            localStorage.removeItem('letAutoReplyState');
            this.clearLogs();
            this.init();
        }
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
                min-width: 250px;
            ">
                <div style="margin-bottom: 10px; font-weight: bold; border-bottom: 1px solid #666; padding-bottom: 5px;">
                    LowEndTalk 自动回复控制面板
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
                    <button id="clear-storage" style="
                        background: #964B4B;
                        border: none;
                        color: white;
                        padding: 5px 10px;
                        border-radius: 4px;
                        cursor: pointer;
                        margin-left: 5px;
                    ">清除记录</button>
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
                <div id="stats-panel" style="
                    margin: 10px 0;
                    padding: 5px;
                    background: #333;
                    border-radius: 4px;
                    font-size: 12px;
                ">
                    <div>运行时间: <span id="runtime">0分钟</span></div>
                    <div>页面刷新次数: <span id="refresh-count">0</span></div>
                    <div>已回复帖子数: <span id="replied-count">0</span></div>
                    <div>上次检查时间: <span id="last-check">-</span></div>
                </div>
                <div id="script-log" style="
                    margin-top: 10px;
                    padding: 5px;
                    background: #333;
                    border-radius: 4px;
                    max-height: 200px;
                    overflow-y: auto;
                    font-size: 12px;
                ">
                    <div>详细日志:</div>
                </div>
            </div>
        `;
        document.body.appendChild(panel);
        setupControlPanelEvents();
        startStatsUpdate();
    }

    // 设置控制面板事件
    function setupControlPanelEvents() {
        const toggleBtn = document.getElementById('toggle-script');
        const statusSpan = document.getElementById('script-status');
        const checkIntervalInput = document.getElementById('check-interval');
        const clearStorageBtn = document.getElementById('clear-storage');
        const resetStatsBtn = document.createElement('button');

        // 添加重置统计按钮
        resetStatsBtn.textContent = '重置统计';
        resetStatsBtn.style.cssText = `
            background: #964B4B;
            border: none;
            color: white;
            padding: 5px 10px;
            border-radius: 4px;
            cursor: pointer;
            margin-left: 5px;
        `;
        clearStorageBtn.parentNode.appendChild(resetStatsBtn);

        // 添加清除日志按钮
        const clearLogsBtn = document.createElement('button');
        clearLogsBtn.textContent = '清除日志';
        clearLogsBtn.style.cssText = `
            background: #964B4B;
            border: none;
            color: white;
            padding: 5px 10px;
            border-radius: 4px;
            cursor: pointer;
            margin-left: 5px;
        `;
        clearStorageBtn.parentNode.appendChild(clearLogsBtn);

        toggleBtn.addEventListener('click', () => {
            config.isRunning = !config.isRunning;
            toggleBtn.textContent = config.isRunning ? '暂停脚本' : '启动脚本';
            statusSpan.textContent = config.isRunning ? '运行中' : '已暂停';
            statusSpan.style.color = config.isRunning ? '#00ff00' : '#ff0000';
            addLog(config.isRunning ? '脚本已启动' : '脚本已暂停');
            scriptState.saveState();
        });

        checkIntervalInput.addEventListener('change', () => {
            config.checkInterval = checkIntervalInput.value * 1000;
            config.refreshInterval = config.checkInterval;
            addLog(`检查间隔已更新为 ${checkIntervalInput.value} 秒`);
        });

        clearStorageBtn.addEventListener('click', () => {
            Object.keys(localStorage).forEach(key => {
                if (key.startsWith('let_replied_')) {
                    localStorage.removeItem(key);
                }
            });
            scriptState.updateStats('repliedPosts', 0);
            addLog('已清除所有回复记录');
        });

        resetStatsBtn.addEventListener('click', () => {
            scriptState.reset();
            addLog('已重置所有统计数据');
            window.location.reload();
        });

        clearLogsBtn.addEventListener('click', () => {
            scriptState.clearLogs();
            updateLogDisplay();
            addLog('已清除所有历史日志');
        });
    }

    // 添加日志
    function addLog(message, type = 'info') {
        const logDiv = document.getElementById('script-log');
        const time = new Date().toLocaleTimeString();
        const colors = {
            info: '#ffffff',
            success: '#00ff00',
            warning: '#ffff00',
            error: '#ff6666',
            debug: '#888888'
        };
        
        // 创建日志条目
        const logEntry = {
            time: new Date().getTime(),
            message,
            type,
            timeString: time
        };
        
        // 保存日志
        scriptState.addLog(logEntry);
        
        // 调试模式下在控制台也输出日志
        if (config.debug) {
            console.log(`[${type.toUpperCase()}] ${message}`);
        }
        
        // 更新显示
        updateLogDisplay();
    }

    // 添加日志显示更新函数
    function updateLogDisplay() {
        const logDiv = document.getElementById('script-log');
        if (!logDiv) return;

        const logs = scriptState.getLogs();
        
        // 构建日志HTML
        let logHtml = '<div>详细日志:</div>';
        logs.forEach(log => {
            const colors = {
                info: '#ffffff',
                success: '#00ff00',
                warning: '#ffff00',
                error: '#ff6666',
                debug: '#888888'
            };
            
            logHtml += `
                <div style="color: ${colors[log.type]}; margin: 2px 0;">
                    [${log.timeString}] ${log.message}
                </div>
            `;
        });
        
        logDiv.innerHTML = logHtml;
        logDiv.scrollTop = logDiv.scrollHeight;
    }

    // 检查是否在用户主页
    function isProfilePage() {
        return window.location.href.includes('/profile/discussions/CLAWCLOUD');
    }

    // 检查是否在帖子页面
    function isDiscussionPage() {
        return window.location.href.includes('/discussion/');
    }

    // 监控用户主页帖子
    function checkPosts() {
        if (!config.isRunning) return;
        
        config.stats.lastCheckTime = new Date();
        addLog('------------------------', 'info');
        addLog('开始新一轮检查', 'info');
        addLog('步骤1: 获取页面帖子列表...', 'info');
        
        // 使用正确的选择器匹配帖子列表
        const discussions = document.querySelectorAll('li[id^="Discussion_"]');
        
        if (!discussions || discussions.length === 0) {
            addLog('❌ 未找到帖子列表，可能页面加载有误', 'warning');
            addLog('等待下次检查...', 'info');
            scheduleNextCheck();
            return;
        }

        addLog(`✅ 成功获取帖子列表，共找到 ${discussions.length} 个帖子`, 'success');
        addLog('步骤2: 开始从上到下检查帖子...', 'info');
        
        // 遍历所有讨论帖子
        for (const discussion of discussions) {
            const discussionId = discussion.id.split('_')[1];
            if (!discussionId) {
                addLog(`❌ 帖子ID解析失败，跳过`, 'warning');
                continue;
            }
            
            addLog(`正在检查帖子 ID: ${discussionId}`, 'info');
            
            // 检查是否是已知帖子
            if (config.knownDiscussionIds.includes(discussionId)) {
                addLog(`📍 遇到已知帖子 ID: ${discussionId}`, 'info');
                addLog(`⚠️ 已知帖子列表: ${config.knownDiscussionIds.join(', ')}`, 'info');
                addLog('🛑 停止检查，因为后面都是旧帖子', 'warning');
                break;
            }
            
            // 找到新帖子，准备点击
            const link = discussion.querySelector('a[href*="/discussion/"]');
            if (link) {
                const title = link.textContent.trim();
                addLog(`🎯 发现新帖子!`, 'success');
                addLog(`标题: ${title}`, 'success');
                addLog(`ID: ${discussionId}`, 'success');
                addLog(`链接: ${link.href}`, 'success');
                addLog(`⏳ 准备进入帖子...`, 'info');
                link.click();
                return;
            }
        }

        addLog('📝 本轮检查总结: 未发现新帖子', 'info');
        addLog(`⏰ 将在 ${config.checkInterval/1000} 秒后重新检查`, 'info');
        addLog('------------------------', 'info');
        scheduleNextCheck();
    }

    // 安排下次检查
    function scheduleNextCheck() {
        if (config.isRunning) {
            scriptState.updateStats('pageRefreshCount', config.stats.pageRefreshCount + 1);
            scriptState.updateStats('lastCheckTime', new Date().getTime());
            addLog(`${config.checkInterval/1000}秒后重新检查...`, 'info');
            setTimeout(() => {
                if (config.isRunning) {
                    addLog('刷新页面...');
                    window.location.reload(true);
                }
            }, config.refreshInterval);
        }
    }

    // 在帖子页面自动回复
    function autoReply() {
        const currentDiscussionId = window.location.pathname.split('/')[2];
        
        addLog('------------------------', 'info');
        addLog('🔄 开始自动回复流程', 'info');
        addLog(`当前帖子ID: ${currentDiscussionId}`, 'info');
        
        // 检查是否已经回复过
        if (localStorage.getItem(`let_replied_${currentDiscussionId}`)) {
            addLog('⚠️ 检测到该帖子已经回复过', 'warning');
            addLog('↩️ 准备返回主页...', 'info');
            setTimeout(() => {
                window.location.href = 'https://lowendtalk.com/profile/discussions/CLAWCLOUD';
            }, 1000);
            return;
        }

        addLog('步骤1: 查找回复框...', 'info');
        const textarea = document.querySelector('textarea[id="Form_Body"]');
        if (textarea) {
            addLog('✅ 找到回复框', 'success');
            addLog(`步骤2: 输入回复内容: "${config.replyContent}"`, 'info');
            textarea.value = config.replyContent;
            
            addLog('步骤3: 查找提交按钮...', 'info');
            const submitButton = document.querySelector('input[id="Form_PostComment"]');
            if (submitButton) {
                addLog('✅ 找到提交按钮', 'success');
                addLog('步骤4: 提交回复...', 'info');
                submitButton.click();
                
                addLog('⏳ 等待回复提交...', 'info');
                setTimeout(() => {
                    config.stats.repliedPosts++;
                    addLog('✅ 回复成功!', 'success');
                    addLog('📊 更新统计: 已回复帖子数 +1', 'info');
                    addLog('↩️ 2秒后返回主页...', 'info');
                    addLog('------------------------', 'info');
                    
                    setTimeout(() => {
                        window.location.href = 'https://lowendtalk.com/profile/discussions/CLAWCLOUD';
                    }, 2000);
                }, 1000);
            } else {
                addLog('❌ 未找到提交按钮', 'error');
                addLog('↩️ 准备返回主页...', 'info');
                setTimeout(() => {
                    window.location.href = 'https://lowendtalk.com/profile/discussions/CLAWCLOUD';
                }, 1000);
            }
        } else {
            addLog('❌ 未找到回复框', 'error');
            addLog('↩️ 准备返回主页...', 'info');
            setTimeout(() => {
                window.location.href = 'https://lowendtalk.com/profile/discussions/CLAWCLOUD';
            }, 1000);
        }
    }

    // 添加统计信息更新函数
    function startStatsUpdate() {
        setInterval(() => {
            const runtimeSpan = document.getElementById('runtime');
            const refreshCountSpan = document.getElementById('refresh-count');
            const repliedCountSpan = document.getElementById('replied-count');
            const lastCheckSpan = document.getElementById('last-check');

            if (runtimeSpan) {
                const runtime = Math.floor((new Date().getTime() - config.stats.startTime) / 60000);
                runtimeSpan.textContent = `${runtime}分钟`;
            }
            if (refreshCountSpan) {
                refreshCountSpan.textContent = config.stats.pageRefreshCount;
            }
            if (repliedCountSpan) {
                repliedCountSpan.textContent = config.stats.repliedPosts;
            }
            if (lastCheckSpan && config.stats.lastCheckTime) {
                lastCheckSpan.textContent = new Date(config.stats.lastCheckTime).toLocaleTimeString();
            }
        }, 1000);
    }

    // 主函数
    function main() {
        scriptState.init();  // 初始化状态
        createControlPanel();
        updateLogDisplay();  // 显示历史日志
        
        if (isProfilePage()) {
            addLog('脚本在用户主页启动');
            checkPosts();
        } else if (isDiscussionPage()) {
            addLog('脚本在帖子页面启动');
            setTimeout(autoReply, 1000);
        }
    }

    // 启动脚本
    main();
})(); 
