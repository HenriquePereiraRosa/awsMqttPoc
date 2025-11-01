# Jenkins vs GitHub Actions: Cost & Practical Analysis

## Quick Answer

**"Better" depends on your needs:**
- ✅ **GitHub Actions is better** for most small/medium projects
- ✅ **Jenkins is better** for enterprise, complex pipelines, or high-volume builds

**Cost:**
- **GitHub Actions**: **FREE** for most projects (2000 min/month private, unlimited public)
- **AWS Jenkins**: **$15-50/month** minimum for a basic setup

---

## Cost Breakdown

### GitHub Actions Pricing (2024)

| Plan | Private Repos | Public Repos |
|------|---------------|--------------|
| **Free** | 2,000 min/month | **Unlimited** |
| **Team** | 3,000 min/month | Unlimited |
| **Enterprise** | 50,000 min/month | Unlimited |

**Cost per minute over limit:**
- Linux: $0.008/min (~$0.48/hour)
- Windows: $0.016/min (~$0.96/hour)
- macOS: $0.08/min (~$4.80/hour)

**Example usage:**
- Our workflow runs ~10 minutes per build
- With 50 builds/month = 500 minutes
- **Cost: $0** (well under 2,000 min limit)

---

### AWS Jenkins Hosting Costs

#### Option 1: Small EC2 Instance (Development)

**Instance:** `t3.medium` (2 vCPU, 4GB RAM)
- **EC2 Cost**: ~$30/month (on-demand)
- **EBS Storage**: ~$5/month (30GB gp3)
- **Data Transfer**: ~$5/month (first 100GB free)
- **Total**: **~$40/month** = **$480/year**

**Pros:**
- Sufficient for small/medium projects
- Can run 2-4 builds in parallel

**Cons:**
- No redundancy (single instance)
- Manual backup/updates

---

#### Option 2: Production Setup (Recommended)

**Instance:** `t3.large` (2 vCPU, 8GB RAM) + Agent
- **Controller**: ~$60/month
- **Build Agent** (t3.medium): ~$30/month
- **EBS Storage**: ~$10/month (50GB)
- **Load Balancer**: ~$20/month (optional)
- **S3 for Artifacts**: ~$5/month
- **Total**: **~$125/month** = **$1,500/year**

**Pros:**
- Production-ready
- Parallel builds
- Better performance
- S3 artifact storage

---

#### Option 3: Container-Based (ECS/EKS)

**ECS Fargate:**
- **Controller**: ~$40/month (0.5 vCPU, 1GB)
- **Build Tasks**: Pay-per-use (~$0.05/hour)
- **Storage**: ~$10/month (EFS)
- **Total**: **~$50-100/month** (variable based on usage)

**EKS (Kubernetes):**
- **Cluster**: ~$75/month (control plane)
- **Nodes**: ~$60/month (2x t3.medium)
- **Total**: **~$135/month** minimum

---

#### Option 4: Lightsail (Simplest)

**Lightsail:**
- **$10/month**: 1 vCPU, 2GB RAM (too small for Jenkins)
- **$20/month**: 2 vCPU, 4GB RAM (minimum viable)
- **$40/month**: 2 vCPU, 8GB RAM (recommended)

**Total**: **~$40/month** = **$480/year**

**Pros:**
- Fixed pricing
- Simpler than EC2
- Includes data transfer

**Cons:**
- Less flexible than EC2
- Limited instance types

---

## Real-World Cost Comparison

### Scenario 1: Small Project (Your POC)

**Usage:**
- 30 builds/month
- 10 minutes/build
- 300 minutes/month

| Solution | Monthly Cost | Yearly Cost | Setup Time |
|----------|--------------|-------------|------------|
| **GitHub Actions** | **$0** ✅ | **$0** ✅ | 5 minutes |
| **AWS EC2 (t3.medium)** | $40 | $480 | 2-4 hours |
| **AWS Lightsail** | $40 | $480 | 1-2 hours |
| **ECS Fargate** | $50-80 | $600-960 | 3-5 hours |

**Winner: GitHub Actions** - Free and ready in minutes

---

### Scenario 2: Medium Project

**Usage:**
- 200 builds/month
- 15 minutes/build
- 3,000 minutes/month

| Solution | Monthly Cost | Yearly Cost | Notes |
|----------|--------------|-------------|-------|
| **GitHub Actions** | **$0** ✅ | **$0** ✅ | Within free tier |
| **AWS EC2** | $40-125 | $480-1,500 | Depending on setup |
| **ECS Fargate** | $80-150 | $960-1,800 | Variable costs |

**Winner: GitHub Actions** - Still free

---

### Scenario 3: Large Project / Enterprise

**Usage:**
- 1,000+ builds/month
- 20 minutes/build
- 20,000+ minutes/month

| Solution | Monthly Cost | Yearly Cost |
|----------|--------------|-------------|
| **GitHub Actions** | **$144** (18k extra min × $0.008) | **$1,728** |
| **AWS EC2 (Production)** | $125-200 | $1,500-2,400 |
| **ECS Fargate** | $150-300 | $1,800-3,600 |

**Winner: Tie** - Costs are similar, choose based on features

---

## Hidden Costs & Considerations

### GitHub Actions Hidden Costs
- ✅ **None!** (within free tier)
- ❌ Limited to GitHub repos
- ❌ 90-day artifact retention

### AWS Jenkins Hidden Costs
- ⚠️ **Maintenance time**: Updates, security patches, backups
- ⚠️ **Monitoring**: CloudWatch costs (~$10/month)
- ⚠️ **Backups**: EBS snapshots (~$5/month)
- ⚠️ **SSL Certificate**: Free with ACM
- ⚠️ **Domain/Route53**: Optional (~$1/month)
- ⚠️ **Learning curve**: Jenkins setup/admin time

**Time Investment:**
- Initial setup: **4-8 hours**
- Monthly maintenance: **2-4 hours**
- At $50/hour: **$100-200/month** in time

**Total Real Cost**: **$140-345/month** (including time)

---

## When to Choose Each

### Choose GitHub Actions If:
✅ You have < 2,000 build minutes/month (or public repo)  
✅ You want **zero cost** for CI/CD  
✅ You want **zero maintenance**  
✅ Your project is on GitHub  
✅ You need quick setup (minutes, not hours)  
✅ You don't need advanced reporting trends  
✅ You're okay with 90-day artifact retention  

**Best for:** Startups, small teams, POCs, open-source projects

---

### Choose Jenkins If:
✅ You need **unlimited build minutes** (cost-effective at scale)  
✅ You need **historical trends** (test/coverage over time)  
✅ You need **unlimited artifact retention**  
✅ You want **self-hosted** (security/compliance)  
✅ You have **multiple Git providers** (GitHub + GitLab + Bitbucket)  
✅ You need **distributed builds** (multiple agents)  
✅ You have **dedicated DevOps** resources  

**Best for:** Enterprise, high-volume builds, compliance requirements

---

## Cost-Break-Even Analysis

### Break-Even Point:
**GitHub Actions becomes more expensive when:**
- You exceed **~18,750 minutes/month** (private repos)
- Calculation: $150/month Jenkins = 18,750 min × $0.008/min

### Your Current Usage Estimate:
Based on your workflow:
- **~10-15 minutes per build**
- **If you run 20 builds/month = 300 minutes**
- **GitHub Actions cost: $0** ✅
- **Jenkins cost: $40-125/month**

**You'd need 100+ builds/month before Jenkins becomes cost-effective!**

---

## AWS Cost Optimization Tips (If You Choose Jenkins)

### 1. Use Spot Instances (70% savings)
- **Regular EC2**: $30/month
- **Spot Instance**: **$9/month** ⚠️ (can be interrupted)

### 2. Use Reserved Instances (40% savings)
- **1-year commitment**: $18/month instead of $30
- **3-year commitment**: $12/month instead of $30

### 3. Auto-Stop During Off-Hours
- Stop instance nights/weekends
- Save **~40%** = **$12/month savings**

### 4. Use Lightsail Instead of EC2
- **Fixed pricing**: $40/month (no surprises)
- Simpler billing

### 5. Archive Old Artifacts to S3 Glacier
- Store old reports in Glacier ($0.004/GB/month)
- **95% cheaper** than keeping on EBS

---

## My Recommendation for Your Project

### For Your AWS MQTT POC:

**Use GitHub Actions** because:

1. ✅ **FREE** ($0 vs $40-125/month)
2. ✅ **Zero maintenance** (no server to manage)
3. ✅ **Already set up** (you have the workflow)
4. ✅ **Sufficient features** (covers your needs)
5. ✅ **Better integration** with GitHub (PR checks, etc.)

**When to Reconsider Jenkins:**

- 🔄 When you exceed 1,500 build minutes/month
- 🔄 When you need test/coverage trends over time
- 🔄 When you need unlimited artifact retention
- 🔄 When you have compliance/security requirements
- 🔄 When you have dedicated DevOps resources

---

## Final Cost Summary

| Solution | Monthly | Yearly | Setup | Maintenance |
|----------|---------|--------|-------|-------------|
| **GitHub Actions** | **$0** ✅ | **$0** ✅ | 5 min | 0 min |
| **Jenkins (AWS)** | **$40-125** | **$480-1,500** | 4-8 hours | 2-4 hrs/month |
| **Jenkins (Real Cost)** | **$140-345** | **$1,680-4,140** | 4-8 hours | 2-4 hrs/month |

**Including your time: Jenkins costs ~$2,000-4,000/year more!**

---

## Conclusion

**For your current project: GitHub Actions wins on cost and simplicity.**

**Jenkins is better if:**
- You have enterprise needs
- High build volume (>18k min/month)
- Need advanced reporting
- Have dedicated DevOps team

**For now: Stick with GitHub Actions, it's free and works great!** 🚀

