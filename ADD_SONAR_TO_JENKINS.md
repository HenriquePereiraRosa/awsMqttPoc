# Add SonarQube/SonarCloud to Jenkins - Complete Guide

## ✅ Yes, SonarQube Reports Are FREE!

### Option 1: SonarCloud (Recommended - Easiest) ✅

**Free Tier**:
- ✅ **Free for private repos** (up to 5 developers)
- ✅ **Up to 50,000 lines of code**
- ✅ **Cloud-hosted** (no setup)
- ✅ **Full analysis** (code quality, security, bugs, vulnerabilities)

**Perfect for your POC!** 🎯

---

### Option 2: SonarQube Community Edition ✅

**Free Tier**:
- ✅ **100% free** (open source)
- ✅ **Unlimited projects**
- ✅ **Self-hosted** (run in Docker)

---

## 🚀 Quick Setup: SonarCloud

### Step 1: Install SonarQube Scanner Plugin in Jenkins

1. **Manage Jenkins** → **Plugins** → **Available**
2. **Search**: `sonarqube-scanner` or "SonarQube Scanner"
3. **Install**: "SonarQube Scanner for Jenkins"

### Step 2: Create SonarCloud Account

1. Go to: **https://sonarcloud.io/**
2. **Sign up with GitHub** (or create account)
3. **Import your repository**: `awsmqttpoc`
4. **Get Project Key & Token**:
   - Project → Administration → Analysis Method → Jenkins
   - Copy the **Project Key** (e.g., `HenriquePereiraRosa_awsmqttpoc`)
   - My Account → Security → Generate Token
   - Copy the **Token**

### Step 3: Configure SonarCloud in Jenkins

1. **Manage Jenkins** → **Configure System**
2. **SonarQube servers** section:
   - **Add SonarQube**
   - **Name**: `SonarCloud`
   - **Server URL**: `https://sonarcloud.io`
   - **Server authentication token**:
     - Add → Jenkins → Secret text
     - Paste your SonarCloud token
     - Save

3. **Manage Jenkins** → **Global Tool Configuration**
4. **SonarQube Scanner** section:
   - **Add SonarQube Scanner**
   - **Name**: `sonar-scanner`
   - **Install automatically**: ✅
   - **Version**: Latest (4.8 or higher)

---

## 📝 Add SonarQube Stage to Jenkinsfile

I'll add a SonarQube scanning stage that runs after tests!

The stage will:
- ✅ Analyze code quality
- ✅ Check for bugs & vulnerabilities
- ✅ Generate coverage report
- ✅ Upload to SonarCloud
- ✅ Display results in Jenkins

---

## 🎯 Benefits

**Code Quality**:
- Code smells detection
- Technical debt tracking
- Code duplication detection
- Maintainability ratings

**Security**:
- Security vulnerabilities
- Security hotspots
- OWASP Top 10 coverage

**Coverage**:
- Integration with JaCoCo coverage
- Coverage trends
- Missing coverage highlighting

---

## 📋 What I'll Add

1. ✅ **SonarQube stage** in Jenkinsfile
2. ✅ **sonar-project.properties** configuration
3. ✅ **Maven SonarQube plugin** setup (optional, if needed)

---

Would you like me to:
1. ✅ **Add SonarCloud stage** to your Jenkinsfile now?
2. ✅ **Create sonar-project.properties** file?
3. ✅ **Both** - Complete SonarCloud integration?

Let me know and I'll set it up! 🚀

