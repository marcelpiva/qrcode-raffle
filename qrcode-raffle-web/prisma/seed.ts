import 'dotenv/config'
import { PrismaClient } from '@prisma/client'

const prisma = new PrismaClient()

// Nomes brasileiros para gerar participantes realistas
const firstNames = [
  'Ana', 'Bruno', 'Carlos', 'Daniela', 'Eduardo', 'Fernanda', 'Gabriel', 'Helena',
  'Igor', 'Julia', 'Lucas', 'Mariana', 'Nicolas', 'Olivia', 'Pedro', 'Rafaela',
  'Samuel', 'Tatiana', 'Victor', 'Amanda', 'Beatriz', 'Caio', 'Débora', 'Felipe',
  'Giovana', 'Henrique', 'Isabela', 'João', 'Karla', 'Leonardo', 'Melissa', 'Nathan',
  'Patricia', 'Ricardo', 'Sabrina', 'Thiago', 'Vanessa', 'William', 'Yasmin', 'André',
  'Bianca', 'Diego', 'Elisa', 'Fabio', 'Gabriela', 'Hugo', 'Ingrid', 'Julio', 'Larissa',
  'Marcelo', 'Natalia', 'Otavio', 'Priscila', 'Renato', 'Sofia', 'Tales', 'Ursula',
  'Vinicius', 'Wesley', 'Ximena', 'Yuri', 'Zelia', 'Arthur', 'Camila', 'Daniel',
  'Eduarda', 'Francisco', 'Gisele', 'Heitor', 'Irene', 'Joaquim', 'Karina', 'Lorenzo',
  'Marina', 'Nuno', 'Paula', 'Rodrigo', 'Sara', 'Tomás', 'Valentina', 'Wagner', 'Antonia'
]

const lastNames = [
  'Silva', 'Santos', 'Oliveira', 'Souza', 'Rodrigues', 'Ferreira', 'Alves', 'Pereira',
  'Lima', 'Gomes', 'Costa', 'Ribeiro', 'Martins', 'Carvalho', 'Almeida', 'Lopes',
  'Soares', 'Fernandes', 'Vieira', 'Barbosa', 'Rocha', 'Dias', 'Nascimento', 'Andrade',
  'Moreira', 'Nunes', 'Marques', 'Machado', 'Mendes', 'Freitas', 'Cardoso', 'Ramos',
  'Gonçalves', 'Santana', 'Teixeira', 'Correia', 'Araújo', 'Pinto', 'Campos', 'Castro'
]

const emailDomains = ['gmail.com', 'hotmail.com', 'outlook.com', 'yahoo.com.br', 'uol.com.br']

function randomItem<T>(arr: T[]): T {
  return arr[Math.floor(Math.random() * arr.length)]
}

function generateName(): string {
  return `${randomItem(firstNames)} ${randomItem(lastNames)}`
}

function generateEmail(name: string, index: number): string {
  const normalized = name
    .toLowerCase()
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/\s+/g, '.')
  return `${normalized}${index}@${randomItem(emailDomains)}`
}

async function main() {
  console.log('🎲 Iniciando seed do banco de dados...\n')

  // Criar sorteio do NAVA Summit
  const raffle = await prisma.raffle.create({
    data: {
      name: 'NAVA Summit 2025 - Grande Sorteio',
      description: 'Sorteio exclusivo para participantes do NAVA Summit 2025! Não perca a chance de ganhar prêmios incríveis.',
      prize: 'iPhone 16 Pro Max + 1 ano de assinatura Premium',
      status: 'active'
    }
  })

  console.log(`✅ Sorteio criado: ${raffle.name}`)
  console.log(`   ID: ${raffle.id}`)
  console.log(`   Prêmio: ${raffle.prize}\n`)

  // Gerar participantes
  const numParticipants = 150
  console.log(`📝 Gerando ${numParticipants} participantes...\n`)

  const participants = []
  const usedEmails = new Set<string>()

  for (let i = 1; i <= numParticipants; i++) {
    const name = generateName()
    let email = generateEmail(name, i)

    // Garantir email único
    while (usedEmails.has(email)) {
      email = generateEmail(name, i + Math.floor(Math.random() * 1000))
    }
    usedEmails.add(email)

    participants.push({
      name,
      email,
      raffleId: raffle.id
    })
  }

  // Inserir participantes em batch
  await prisma.participant.createMany({
    data: participants
  })

  console.log(`✅ ${numParticipants} participantes criados com sucesso!\n`)

  // Mostrar alguns exemplos
  console.log('📋 Exemplos de participantes:')
  const examples = await prisma.participant.findMany({
    where: { raffleId: raffle.id },
    take: 5,
    orderBy: { createdAt: 'asc' }
  })

  examples.forEach((p, i) => {
    console.log(`   ${i + 1}. ${p.name} (${p.email})`)
  })

  console.log('\n🎉 Seed concluído com sucesso!')
  console.log(`\n📱 Acesse /admin/${raffle.id} para gerenciar o sorteio`)
}

main()
  .catch((e) => {
    console.error('❌ Erro durante seed:', e)
    process.exit(1)
  })
  .finally(async () => {
    await prisma.$disconnect()
  })
