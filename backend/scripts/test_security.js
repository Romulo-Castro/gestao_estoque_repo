// scripts/test_security.js
const axios = require('axios');

const BASE_URL = process.env.BASE_URL || 'http://localhost:3000';

console.log('🔒 Testando medidas de segurança...\n');

async function testRateLimit() {
    console.log('📊 Testando Rate Limiting...');
    try {
        const promises = [];
        // Fazer 10 requisições simultâneas para testar rate limiting
        for (let i = 0; i < 10; i++) {
            promises.push(
                axios.get(`${BASE_URL}/api`, { timeout: 5000 })
                    .then(() => ({ success: true, index: i }))
                    .catch(error => ({ 
                        success: false, 
                        index: i, 
                        status: error.response?.status,
                        message: error.response?.data?.error || error.message
                    }))
            );
        }
        
        const results = await Promise.all(promises);
        const successful = results.filter(r => r.success).length;
        const blocked = results.filter(r => !r.success && r.status === 429).length;
        
        console.log(`✅ Rate Limiting: ${successful} sucessos, ${blocked} bloqueadas`);
        
        if (blocked > 0) {
            console.log('✅ Rate limiting funcionando corretamente');
        } else {
            console.log('⚠️ Rate limiting pode não estar funcionando');
        }
    } catch (error) {
        console.log('❌ Erro ao testar rate limiting:', error.message);
    }
}

async function testAuthRateLimit() {
    console.log('\n🔐 Testando Rate Limiting de Autenticação...');
    try {
        const promises = [];
        // Fazer 8 tentativas de login para testar rate limiting específico de auth
        for (let i = 0; i < 8; i++) {
            promises.push(
                axios.post(`${BASE_URL}/api/auth/login`, {
                    email: 'test@test.com',
                    password: 'wrongpassword'
                }, { timeout: 5000 })
                    .then(() => ({ success: true, index: i }))
                    .catch(error => ({ 
                        success: false, 
                        index: i, 
                        status: error.response?.status,
                        message: error.response?.data?.error || error.message
                    }))
            );
        }
        
        const results = await Promise.all(promises);
        const blocked = results.filter(r => !r.success && r.status === 429).length;
        
        console.log(`✅ Auth Rate Limiting: ${blocked} tentativas bloqueadas`);
        
        if (blocked > 0) {
            console.log('✅ Rate limiting de autenticação funcionando');
        } else {
            console.log('⚠️ Rate limiting de auth pode não estar funcionando');
        }
    } catch (error) {
        console.log('❌ Erro ao testar auth rate limiting:', error.message);
    }
}

async function testSecurityHeaders() {
    console.log('\n🛡️ Testando Headers de Segurança...');
    try {
        const response = await axios.get(`${BASE_URL}/api`, { timeout: 5000 });
        const headers = response.headers;
        
        const expectedHeaders = [
            'x-content-type-options',
            'x-frame-options',
            'x-xss-protection',
            'strict-transport-security'
        ];
        
        const foundHeaders = expectedHeaders.filter(header => headers[header]);
        
        console.log(`✅ Headers de segurança encontrados: ${foundHeaders.length}/${expectedHeaders.length}`);
        foundHeaders.forEach(header => {
            console.log(`  ✓ ${header}: ${headers[header]}`);
        });
        
        const missingHeaders = expectedHeaders.filter(header => !headers[header]);
        if (missingHeaders.length > 0) {
            console.log('⚠️ Headers ausentes:', missingHeaders.join(', '));
        }
    } catch (error) {
        console.log('❌ Erro ao testar headers de segurança:', error.message);
    }
}

async function testSuspiciousRequests() {
    console.log('\n🕵️ Testando Detecção de Requisições Suspeitas...');
    
    const suspiciousPayloads = [
        { type: 'XSS', data: { input: '<script>alert("xss")</script>' } },
        { type: 'SQL Injection', data: { query: "' UNION SELECT * FROM users --" } },
        { type: 'Directory Traversal', url: '/api/../../../etc/passwd' },
        { type: 'Command Injection', data: { command: 'cmd.exe /c dir' } }
    ];
    
    for (const payload of suspiciousPayloads) {
        try {
            const url = payload.url ? `${BASE_URL}${payload.url}` : `${BASE_URL}/api`;
            await axios.post(url, payload.data || {}, { timeout: 5000 });
            console.log(`⚠️ ${payload.type}: Não detectado/bloqueado`);
        } catch (error) {
            if (error.response?.status >= 400) {
                console.log(`✅ ${payload.type}: Detectado/bloqueado`);
            } else {
                console.log(`❓ ${payload.type}: ${error.message}`);
            }
        }
    }
}

async function testHealthCheck() {
    console.log('\n❤️ Testando Health Check...');
    try {
        const response = await axios.get(`${BASE_URL}/health`, { timeout: 5000 });
        if (response.status === 200 && response.data.status === 'ok') {
            console.log('✅ Health check funcionando');
            console.log(`  Uptime: ${Math.floor(response.data.uptime)}s`);
            console.log(`  Environment: ${response.data.environment}`);
        } else {
            console.log('❌ Health check retornou status inválido');
        }
    } catch (error) {
        console.log('❌ Health check falhou:', error.message);
    }
}

async function runSecurityTests() {
    console.log(`🎯 Testando servidor em: ${BASE_URL}\n`);
    
    try {
        // Testar se o servidor está rodando
        await axios.get(`${BASE_URL}/api`, { timeout: 5000 });
        console.log('✅ Servidor está respondendo\n');
        
        await testHealthCheck();
        await testSecurityHeaders();
        await testRateLimit();
        await testAuthRateLimit();
        await testSuspiciousRequests();
        
        console.log('\n🏁 Testes de segurança concluídos');
        
    } catch (error) {
        console.log('❌ Erro: Servidor não está respondendo');
        console.log('💡 Certifique-se de que o servidor está rodando em:', BASE_URL);
        console.log('   Execute: npm run dev');
        process.exit(1);
    }
}

// Executar testes
runSecurityTests();
