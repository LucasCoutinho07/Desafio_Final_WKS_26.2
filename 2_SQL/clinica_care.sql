-- ================================================================
-- clinica_care.sql — Desafio Final 2026.2 (ClínicaCare), Módulo 2: SQL
-- Uso: mysql -u root -p < clinica_care.sql
-- ================================================================

DROP DATABASE IF EXISTS clinica_care;
CREATE DATABASE clinica_care CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE clinica_care;

-- ================================================================
-- DDL — Criação das tabelas
-- ================================================================

-- Criação da tabela convenios
CREATE TABLE convenios (
    id_convenio           INT AUTO_INCREMENT PRIMARY KEY,
    nome                  VARCHAR(100) NOT NULL,
    tipo                  ENUM('Particular','Convenio') NOT NULL,
    registro_ans          VARCHAR(20) NULL,
    telefone_contato      VARCHAR(20),
    email_contato         VARCHAR(120),
    percentual_cobertura  DECIMAL(5,2),
    ativo                 BOOLEAN NOT NULL DEFAULT TRUE,
    data_cadastro         DATE NOT NULL DEFAULT (CURRENT_DATE),
    CONSTRAINT uq_convenios_nome UNIQUE (nome)
) ENGINE=InnoDB;

-- Criação da tabela especialidades
CREATE TABLE especialidades (
    id_especialidade        INT AUTO_INCREMENT PRIMARY KEY,
    nome_especialidade      VARCHAR(100) NOT NULL,
    descricao                VARCHAR(255),
    duracao_padrao_minutos  INT,
    valor_base               DECIMAL(10,2),
    requer_encaminhamento   BOOLEAN NOT NULL DEFAULT FALSE,
    ativo                    BOOLEAN NOT NULL DEFAULT TRUE,
    data_cadastro            DATE NOT NULL DEFAULT (CURRENT_DATE),
    CONSTRAINT uq_especialidades_nome UNIQUE (nome_especialidade)
) ENGINE=InnoDB;

-- Criação da tabela medicos
CREATE TABLE medicos (
    id_medico       INT AUTO_INCREMENT PRIMARY KEY,
    nome_completo   VARCHAR(150) NOT NULL,
    crm             VARCHAR(20) NOT NULL,
    crm_uf          CHAR(2) NOT NULL,
    telefone        VARCHAR(20),
    email           VARCHAR(120) UNIQUE,
    data_admissao   DATE,
    status_ativo    BOOLEAN NOT NULL DEFAULT TRUE,
    data_cadastro   DATE NOT NULL DEFAULT (CURRENT_DATE),
    CONSTRAINT uq_medicos_crm UNIQUE (crm, crm_uf)
) ENGINE=InnoDB;

-- Criação da tabela pacientes (id_convenio é NOT NULL; pacientes sem plano usam a linha "Particular")
CREATE TABLE pacientes (
    id_paciente      INT AUTO_INCREMENT PRIMARY KEY,
    nome_completo    VARCHAR(150) NOT NULL,
    cpf              VARCHAR(14) NOT NULL UNIQUE,
    data_nascimento  DATE NOT NULL,
    genero           VARCHAR(20),
    endereco         VARCHAR(200),
    telefone         VARCHAR(20),
    email            VARCHAR(120),
    id_convenio      INT NOT NULL,
    data_cadastro    DATE NOT NULL DEFAULT (CURRENT_DATE),
    CONSTRAINT fk_pacientes_convenio FOREIGN KEY (id_convenio) REFERENCES convenios(id_convenio)
) ENGINE=InnoDB;

-- Criação da tabela medico_especialidade (associativa — resolve N:N medicos x especialidades)
CREATE TABLE medico_especialidade (
    id_medico         INT NOT NULL,
    id_especialidade  INT NOT NULL,
    principal         BOOLEAN NOT NULL DEFAULT FALSE,
    data_registro     DATE NOT NULL DEFAULT (CURRENT_DATE),
    PRIMARY KEY (id_medico, id_especialidade),
    CONSTRAINT fk_medesp_medico FOREIGN KEY (id_medico) REFERENCES medicos(id_medico),
    CONSTRAINT fk_medesp_especialidade FOREIGN KEY (id_especialidade) REFERENCES especialidades(id_especialidade)
) ENGINE=InnoDB;

-- Criação da tabela horarios_disponibilidade
CREATE TABLE horarios_disponibilidade (
    id_horario      INT AUTO_INCREMENT PRIMARY KEY,
    id_medico       INT NOT NULL,
    dia_semana      TINYINT NOT NULL COMMENT '1=Domingo ... 7=Sabado',
    hora_inicio     TIME NOT NULL,
    hora_fim        TIME NOT NULL,
    modalidade      ENUM('Presencial','Telemedicina') NOT NULL DEFAULT 'Presencial',
    ativo           BOOLEAN NOT NULL DEFAULT TRUE,
    data_cadastro   DATE NOT NULL DEFAULT (CURRENT_DATE),
    CONSTRAINT fk_horarios_medico FOREIGN KEY (id_medico) REFERENCES medicos(id_medico)
) ENGINE=InnoDB;

-- Criação da tabela consultas
CREATE TABLE consultas (
    id_consulta        INT AUTO_INCREMENT PRIMARY KEY,
    id_paciente        INT NOT NULL,
    id_medico          INT NOT NULL,
    id_especialidade   INT NOT NULL,
    data_consulta      DATE NOT NULL,
    hora_consulta      TIME NOT NULL,
    status             ENUM('Agendada','Realizada','Cancelada','Faltou') NOT NULL DEFAULT 'Agendada',
    valor              DECIMAL(10,2) NOT NULL,
    data_agendamento   DATETIME NOT NULL,
    observacoes        VARCHAR(255),
    CONSTRAINT fk_consultas_paciente FOREIGN KEY (id_paciente) REFERENCES pacientes(id_paciente),
    CONSTRAINT fk_consultas_medico FOREIGN KEY (id_medico) REFERENCES medicos(id_medico),
    CONSTRAINT fk_consultas_especialidade FOREIGN KEY (id_especialidade) REFERENCES especialidades(id_especialidade),
    -- impede o mesmo médico de ser agendado duas vezes no mesmo horário
    CONSTRAINT uq_consultas_agenda_medico UNIQUE (id_medico, data_consulta, hora_consulta)
    -- LIMITAÇÃO CONHECIDA: a FK não garante que id_especialidade pertença ao id_medico; consistência garantida no DML e validada após a carga
) ENGINE=InnoDB;

-- Criação da tabela prontuarios (1:1 com pacientes)
CREATE TABLE prontuarios (
    id_prontuario                  INT AUTO_INCREMENT PRIMARY KEY,
    id_paciente                    INT NOT NULL UNIQUE,
    data_abertura                  DATE NOT NULL,
    tipo_sanguineo                 VARCHAR(3),
    alergias_conhecidas            VARCHAR(255),
    historico_familiar_relevante   VARCHAR(255),
    observacoes_gerais             VARCHAR(500),
    data_ultima_atualizacao        DATETIME,
    CONSTRAINT fk_prontuarios_paciente FOREIGN KEY (id_paciente) REFERENCES pacientes(id_paciente)
) ENGINE=InnoDB;

-- Criação da tabela evolucoes (1:1 com consultas — registro clínico de cada consulta realizada)
CREATE TABLE evolucoes (
    id_evolucao        INT AUTO_INCREMENT PRIMARY KEY,
    id_consulta        INT NOT NULL UNIQUE,
    data_registro      DATETIME NOT NULL,
    queixa_principal   VARCHAR(255),
    diagnostico        VARCHAR(255),
    anotacoes_medico   TEXT,
    cid                VARCHAR(10),
    conduta            VARCHAR(255),
    CONSTRAINT fk_evolucoes_consulta FOREIGN KEY (id_consulta) REFERENCES consultas(id_consulta)
) ENGINE=InnoDB;

-- Criação da tabela prescricoes (1:N com evolucoes)
CREATE TABLE prescricoes (
    id_prescricao             INT AUTO_INCREMENT PRIMARY KEY,
    id_evolucao               INT NOT NULL,
    medicamento               VARCHAR(150) NOT NULL,
    dosagem                   VARCHAR(50),
    posologia                 VARCHAR(150),
    quantidade                INT,
    duracao_tratamento_dias   INT,
    data_prescricao           DATE NOT NULL,
    observacoes                VARCHAR(255),
    CONSTRAINT fk_prescricoes_evolucao FOREIGN KEY (id_evolucao) REFERENCES evolucoes(id_evolucao)
) ENGINE=InnoDB;

-- Criação da tabela pagamentos (1:1 com consultas)
CREATE TABLE pagamentos (
    id_pagamento       INT AUTO_INCREMENT PRIMARY KEY,
    id_consulta        INT NOT NULL UNIQUE,
    valor              DECIMAL(10,2) NOT NULL,
    data_pagamento     DATE,
    metodo_pagamento   ENUM('Dinheiro','Cartao','Pix'),
    status_pagamento   ENUM('Pendente','Pago','Cancelado') NOT NULL DEFAULT 'Pendente',
    numero_recibo      VARCHAR(30) UNIQUE,
    data_vencimento    DATE,
    observacoes        VARCHAR(255),
    CONSTRAINT fk_pagamentos_consulta FOREIGN KEY (id_consulta) REFERENCES consultas(id_consulta)
) ENGINE=InnoDB;

-- ================================================================
-- Índices adicionais (status e data_consulta não são FK, logo não têm índice automático)
-- ================================================================
CREATE INDEX idx_consultas_status ON consultas(status);
CREATE INDEX idx_consultas_data ON consultas(data_consulta);
CREATE INDEX idx_pagamentos_status ON pagamentos(status_pagamento);

-- ================================================================
-- DML — Inserção de dados
-- pacientes/medicos/especialidades/convenios: 12-20 registros (enunciado).
-- consultas/pagamentos: volume maior de propósito, para alimentar o modelo
-- de ML do Módulo 3. Dados gerados via script Python (semente fixa),
-- respeitando integridade referencial e regras de negócio.
-- ================================================================

-- ============================================================
-- Inserção de dados — convenios
-- ============================================================

INSERT INTO convenios (nome, tipo, registro_ans, telefone_contato, email_contato, percentual_cobertura, ativo, data_cadastro) VALUES
  ('Particular', 'Particular', NULL, NULL, NULL, NULL, TRUE, '2022-07-12'),
  ('Unimed Joao Pessoa', 'Convenio', 'ANS-12345', '(83) 95506-5012', 'contato@unimed.joao.pessoa.com.br', 80.0, TRUE, '2025-06-27'),
  ('Bradesco Saude', 'Convenio', 'ANS-23456', '(83) 92679-9935', 'contato@bradesco.saude.com.br', 70.0, TRUE, '2024-11-10'),
  ('SulAmerica Saude', 'Convenio', 'ANS-34567', '(84) 97912-1520', 'contato@sulamerica.saude.com.br', 75.0, TRUE, '2025-08-16'),
  ('Amil', 'Convenio', 'ANS-45678', '(83) 94582-4811', 'contato@amil.com.br', 65.0, TRUE, '2025-12-11'),
  ('Hapvida', 'Convenio', 'ANS-56789', '(84) 91434-4257', 'contato@hapvida.com.br', 60.0, TRUE, '2023-04-13'),
  ('NotreDame Intermedica', 'Convenio', 'ANS-67890', '(84) 99928-7873', 'contato@notredame.intermedica.com.br', 65.0, TRUE, '2022-02-05'),
  ('Golden Cross', 'Convenio', 'ANS-78901', '(81) 95557-1106', 'contato@golden.cross.com.br', 55.0, TRUE, '2024-11-16'),
  ('Porto Seguro Saude', 'Convenio', 'ANS-89012', '(83) 97924-6574', 'contato@porto.seguro.saude.com.br', 70.0, TRUE, '2021-11-09'),
  ('Central Nacional Unimed', 'Convenio', 'ANS-90123', '(83) 94527-6514', 'contato@central.nacional.unimed.com.br', 80.0, TRUE, '2024-07-21'),
  ('Ipasgo', 'Convenio', 'ANS-01234', '(83) 97224-2584', 'contato@ipasgo.com.br', 50.0, TRUE, '2025-07-16'),
  ('Cassi', 'Convenio', 'ANS-11223', '(81) 95333-1711', 'contato@cassi.com.br', 60.0, TRUE, '2024-02-06'),
  ('GEAP Saude', 'Convenio', 'ANS-22334', '(81) 99785-3045', 'contato@geap.saude.com.br', 55.0, TRUE, '2022-01-08'),
  ('Sao Francisco Saude', 'Convenio', 'ANS-33445', '(83) 95803-6925', 'contato@sao.francisco.saude.com.br', 60.0, TRUE, '2023-12-28');

-- ============================================================
-- Inserção de dados — especialidades
-- ============================================================

INSERT INTO especialidades (nome_especialidade, descricao, duracao_padrao_minutos, valor_base, requer_encaminhamento, ativo, data_cadastro) VALUES
  ('Clinica Geral', 'Atendimento clinico geral e check-ups', 30, 150.0, FALSE, TRUE, '2022-11-16'),
  ('Cardiologia', 'Diagnostico e tratamento de doencas do coracao', 40, 280.0, TRUE, TRUE, '2025-01-13'),
  ('Dermatologia', 'Tratamento de doencas de pele', 30, 220.0, FALSE, TRUE, '2022-03-01'),
  ('Pediatria', 'Atendimento medico infantil', 30, 180.0, FALSE, TRUE, '2025-09-21'),
  ('Ginecologia e Obstetricia', 'Saude da mulher e acompanhamento gestacional', 40, 250.0, FALSE, TRUE, '2025-11-09'),
  ('Ortopedia', 'Tratamento de ossos, articulacoes e musculos', 30, 230.0, TRUE, TRUE, '2022-05-28'),
  ('Psiquiatria', 'Saude mental e transtornos psiquiatricos', 50, 300.0, TRUE, TRUE, '2024-11-01'),
  ('Oftalmologia', 'Diagnostico e tratamento de doencas oculares', 30, 200.0, FALSE, TRUE, '2021-10-11'),
  ('Endocrinologia', 'Tratamento de disturbios hormonais e metabolicos', 30, 260.0, TRUE, TRUE, '2024-06-28'),
  ('Neurologia', 'Diagnostico de doencas do sistema nervoso', 40, 290.0, TRUE, TRUE, '2025-08-31'),
  ('Urologia', 'Saude do sistema urinario e reprodutor masculino', 30, 240.0, FALSE, TRUE, '2024-10-22'),
  ('Otorrinolaringologia', 'Tratamento de ouvido, nariz e garganta', 30, 210.0, FALSE, TRUE, '2025-07-19'),
  ('Gastroenterologia', 'Tratamento do sistema digestivo', 30, 250.0, TRUE, TRUE, '2023-12-25'),
  ('Reumatologia', 'Tratamento de doencas reumaticas e autoimunes', 40, 270.0, TRUE, TRUE, '2024-07-21');

-- ============================================================
-- Inserção de dados — medicos
-- ============================================================

INSERT INTO medicos (nome_completo, crm, crm_uf, telefone, email, data_admissao, status_ativo, data_cadastro) VALUES
  ('Aline Carvalho Pereira', '58520', 'PB', '(84) 95374-2169', 'aline.carvalho.pereira@clinicacare.com.br', '2023-10-26', TRUE, '2023-10-26'),
  ('Bruno Nascimento Pereira', '70589', 'PB', '(84) 94598-6313', 'bruno.nascimento.pereira@clinicacare.com.br', '2023-02-21', TRUE, '2023-02-21'),
  ('Marcelo Santos Ribeiro', '62581', 'PB', '(83) 96155-4483', 'marcelo.santos.ribeiro@clinicacare.com.br', '2025-06-04', TRUE, '2025-06-04'),
  ('Beatriz Rocha Costa', '44718', 'PB', '(84) 99830-5304', 'beatriz.rocha.costa@clinicacare.com.br', '2023-05-27', TRUE, '2023-05-27'),
  ('Sabrina Medeiros Gomes', '57447', 'PB', '(84) 99085-2489', 'sabrina.medeiros.gomes@clinicacare.com.br', '2024-08-13', TRUE, '2024-08-13'),
  ('Felipe Souza Costa', '92240', 'PB', '(84) 97916-2040', 'felipe.souza.costa@clinicacare.com.br', '2017-04-14', TRUE, '2017-04-14'),
  ('Beatriz Bandeira Rocha', '79352', 'PB', '(83) 92876-9797', 'beatriz.bandeira.rocha@clinicacare.com.br', '2019-12-18', TRUE, '2019-12-18'),
  ('Vanessa Ribeiro Souza', '48469', 'PB', '(81) 91053-5315', 'vanessa.ribeiro.souza@clinicacare.com.br', '2024-05-24', TRUE, '2024-05-24'),
  ('Bruno Souza Araujo', '93748', 'RN', '(83) 93504-7126', 'bruno.souza.araujo@clinicacare.com.br', '2019-05-04', TRUE, '2019-05-04'),
  ('Bruno Cavalcanti Silva', '88504', 'PB', '(83) 92832-6947', 'bruno.cavalcanti.silva@clinicacare.com.br', '2020-09-08', TRUE, '2020-09-08'),
  ('Patricia Santos Nascimento', '84364', 'PB', '(84) 98962-2133', 'patricia.santos.nascimento@clinicacare.com.br', '2025-03-17', TRUE, '2025-03-17'),
  ('Fernando Barbosa Dantas', '31643', 'PB', '(84) 97932-4470', 'fernando.barbosa.dantas@clinicacare.com.br', '2020-04-01', TRUE, '2020-04-01'),
  ('Andre Araujo Gomes', '98039', 'PB', '(84) 98397-2982', 'andre.araujo.gomes@clinicacare.com.br', '2021-04-03', TRUE, '2021-04-03');

-- ============================================================
-- Inserção de dados — pacientes
-- ============================================================

INSERT INTO pacientes (nome_completo, cpf, data_nascimento, genero, endereco, telefone, email, id_convenio, data_cadastro) VALUES
  ('Rodrigo Santos Carvalho', '692.322.602-39', '1998-09-21', 'Masculino', 'Rua Souza, 734, Expedicionarios, Joao Pessoa - PB', '(84) 96442-7745', 'rodrigo.santos.carvalho@email.com', 1, '2023-06-10'),
  ('Fernanda Pereira Souza', '543.303.654-56', '1977-08-22', 'Feminino', 'Rua Nascimento, 418, Jose Americo, Joao Pessoa - PB', '(83) 95573-6753', 'fernanda.pereira.souza@email.com', 10, '2023-12-31'),
  ('Thiago Dantas Ribeiro', '019.655.698-89', '2022-07-02', 'Masculino', 'Rua Lima, 375, Torre, Joao Pessoa - PB', '(83) 97311-4114', 'thiago.dantas.ribeiro@email.com', 11, '2025-02-02'),
  ('Carlos Martins Silva', '595.148.465-08', '1958-12-14', 'Masculino', 'Rua Almeida, 755, Bancarios, Joao Pessoa - PB', '(81) 95844-3085', 'carlos.martins.silva@email.com', 6, '2026-03-09'),
  ('Beatriz Gomes Pereira', '436.995.777-08', '1946-12-01', 'Feminino', 'Rua Dantas, 1717, Cabo Branco, Joao Pessoa - PB', '(84) 94501-9375', 'beatriz.gomes.pereira@email.com', 1, '2024-11-15'),
  ('Diego Pereira Oliveira', '433.200.379-94', '1988-12-18', 'Masculino', 'Rua Bandeira, 696, Tambau, Joao Pessoa - PB', '(83) 98461-7790', 'diego.pereira.oliveira@email.com', 6, '2025-04-05'),
  ('Priscila Gomes Barbosa', '632.870.831-98', '1974-05-10', 'Feminino', 'Rua Silva, 1838, Expedicionarios, Joao Pessoa - PB', '(81) 93184-8612', 'priscila.gomes.barbosa@email.com', 1, '2025-12-24'),
  ('Diego Rocha Bandeira', '743.487.347-71', '1961-02-08', 'Masculino', 'Rua Dantas, 923, Manaira, Joao Pessoa - PB', '(83) 95681-4841', 'diego.rocha.bandeira@email.com', 9, '2023-12-01'),
  ('Ricardo Ribeiro Dantas', '316.658.760-85', '2015-06-23', 'Masculino', 'Rua Gomes, 1431, Manaira, Joao Pessoa - PB', '(83) 97883-7381', 'ricardo.ribeiro.dantas@email.com', 1, '2022-08-14'),
  ('Livia Medeiros Gomes', '889.373.467-29', '1964-09-10', 'Feminino', 'Rua Araujo, 1553, Bancarios, Joao Pessoa - PB', '(83) 97371-6507', 'livia.medeiros.gomes@email.com', 13, '2024-03-24'),
  ('Andre Pereira Rocha', '016.272.046-79', '2008-10-19', 'Masculino', 'Rua Gomes, 1222, Torre, Joao Pessoa - PB', '(81) 94467-8449', 'andre.pereira.rocha@email.com', 4, '2022-11-11'),
  ('Ricardo Gomes Lima', '053.100.330-25', '1972-05-05', 'Masculino', 'Rua Barbosa, 49, Valentina, Joao Pessoa - PB', '(84) 93496-4908', 'ricardo.gomes.lima@email.com', 9, '2023-07-22'),
  ('Larissa Souza Medeiros', '124.190.496-08', '1998-01-10', 'Feminino', 'Rua Carvalho, 353, Torre, Joao Pessoa - PB', '(81) 94249-2245', 'larissa.souza.medeiros@email.com', 7, '2023-03-05'),
  ('Mariana Araujo Bandeira', '518.506.716-05', '2009-11-17', 'Feminino', 'Rua Carvalho, 1101, Bancarios, Joao Pessoa - PB', '(81) 98532-3506', 'mariana.araujo.bandeira@email.com', 8, '2022-11-14'),
  ('Fernando Cavalcanti Lima', '453.147.379-57', '1946-12-17', 'Masculino', 'Rua Rocha, 902, Jose Americo, Joao Pessoa - PB', '(84) 97209-6511', 'fernando.cavalcanti.lima@email.com', 8, '2023-04-04'),
  ('Larissa Ribeiro Pereira', '480.831.367-78', '1963-05-29', 'Feminino', 'Rua Lima, 707, Miramar, Joao Pessoa - PB', '(84) 94937-8800', 'larissa.ribeiro.pereira@email.com', 2, '2023-03-28'),
  ('Rafael Silva Oliveira', '578.856.855-27', '1988-05-17', 'Masculino', 'Rua Nascimento, 637, Mangabeira, Joao Pessoa - PB', '(84) 98434-5438', 'rafael.silva.oliveira@email.com', 3, '2023-04-26'),
  ('Paulo Nascimento Souza', '233.749.894-89', '2001-03-27', 'Masculino', 'Rua Dantas, 1957, Expedicionarios, Joao Pessoa - PB', '(83) 94180-5853', 'paulo.nascimento.souza@email.com', 1, '2022-09-16'),
  ('Camila Pereira Araujo', '427.109.477-30', '2023-09-02', 'Feminino', 'Rua Lima, 103, Cabo Branco, Joao Pessoa - PB', '(81) 96582-4020', 'camila.pereira.araujo@email.com', 4, '2023-06-23');

-- ============================================================
-- Inserção de dados — medico_especialidade
-- ============================================================

INSERT INTO medico_especialidade (id_medico, id_especialidade, principal, data_registro) VALUES
  (1, 11, TRUE, '2020-11-11'),
  (1, 4, FALSE, '2017-02-10'),
  (2, 8, TRUE, '2021-08-08'),
  (3, 3, TRUE, '2024-01-13'),
  (4, 7, TRUE, '2025-02-09'),
  (5, 10, TRUE, '2025-01-29'),
  (5, 14, FALSE, '2018-10-11'),
  (6, 12, TRUE, '2021-05-02'),
  (7, 5, TRUE, '2022-03-12'),
  (7, 6, FALSE, '2021-06-02'),
  (8, 13, TRUE, '2021-07-23'),
  (8, 7, FALSE, '2020-12-06'),
  (9, 9, TRUE, '2017-12-28'),
  (9, 13, FALSE, '2025-07-24'),
  (10, 1, TRUE, '2018-08-13'),
  (10, 4, FALSE, '2018-11-03'),
  (11, 6, TRUE, '2018-12-03'),
  (11, 1, FALSE, '2025-01-23'),
  (12, 2, TRUE, '2025-06-27'),
  (13, 14, TRUE, '2021-08-26');

-- ============================================================
-- Inserção de dados — horarios_disponibilidade
-- ============================================================

INSERT INTO horarios_disponibilidade (id_medico, dia_semana, hora_inicio, hora_fim, modalidade, ativo, data_cadastro) VALUES
  (1, 2, '09:00:00', '12:00:00', 'Presencial', TRUE, '2025-10-10'),
  (1, 3, '14:00:00', '18:00:00', 'Presencial', TRUE, '2024-11-14'),
  (1, 6, '09:00:00', '12:00:00', 'Presencial', TRUE, '2025-12-15'),
  (2, 6, '08:00:00', '12:00:00', 'Presencial', TRUE, '2024-01-21'),
  (2, 2, '09:00:00', '12:00:00', 'Presencial', TRUE, '2024-10-21'),
  (2, 5, '14:00:00', '18:00:00', 'Presencial', TRUE, '2025-01-16'),
  (3, 3, '08:00:00', '12:00:00', 'Presencial', TRUE, '2025-06-04'),
  (3, 5, '14:00:00', '18:00:00', 'Presencial', TRUE, '2024-03-19'),
  (4, 3, '09:00:00', '12:00:00', 'Presencial', TRUE, '2024-07-17'),
  (4, 6, '08:00:00', '12:00:00', 'Presencial', TRUE, '2026-01-03'),
  (4, 5, '08:00:00', '12:00:00', 'Presencial', TRUE, '2024-10-04'),
  (5, 2, '09:00:00', '12:00:00', 'Telemedicina', TRUE, '2025-12-23'),
  (5, 6, '09:00:00', '12:00:00', 'Presencial', TRUE, '2024-07-27'),
  (6, 6, '08:00:00', '12:00:00', 'Presencial', TRUE, '2024-07-13'),
  (6, 2, '13:00:00', '18:00:00', 'Presencial', TRUE, '2025-08-05'),
  (7, 3, '09:00:00', '12:00:00', 'Presencial', TRUE, '2025-04-29'),
  (7, 4, '14:00:00', '18:00:00', 'Presencial', TRUE, '2024-01-23'),
  (7, 6, '08:00:00', '12:00:00', 'Telemedicina', TRUE, '2024-06-04'),
  (8, 2, '13:00:00', '18:00:00', 'Telemedicina', TRUE, '2025-03-10'),
  (8, 3, '08:00:00', '12:00:00', 'Presencial', TRUE, '2025-02-17'),
  (9, 3, '13:00:00', '18:00:00', 'Presencial', TRUE, '2024-05-02'),
  (9, 5, '08:00:00', '12:00:00', 'Presencial', TRUE, '2024-08-12'),
  (9, 4, '13:00:00', '18:00:00', 'Presencial', TRUE, '2025-11-16'),
  (10, 4, '08:00:00', '12:00:00', 'Presencial', TRUE, '2025-09-24'),
  (10, 2, '13:00:00', '18:00:00', 'Presencial', TRUE, '2025-07-30'),
  (11, 3, '14:00:00', '18:00:00', 'Presencial', TRUE, '2026-01-09'),
  (11, 4, '08:00:00', '12:00:00', 'Presencial', TRUE, '2025-05-23'),
  (11, 5, '08:00:00', '12:00:00', 'Telemedicina', TRUE, '2024-01-03'),
  (12, 4, '14:00:00', '18:00:00', 'Presencial', TRUE, '2024-12-20'),
  (12, 3, '08:00:00', '12:00:00', 'Telemedicina', TRUE, '2024-03-25'),
  (13, 6, '13:00:00', '18:00:00', 'Presencial', TRUE, '2025-10-02'),
  (13, 2, '14:00:00', '18:00:00', 'Telemedicina', TRUE, '2025-04-21');

-- ============================================================
-- Inserção de dados — consultas
-- ============================================================

INSERT INTO consultas (id_paciente, id_medico, id_especialidade, data_consulta, hora_consulta, status, valor, data_agendamento, observacoes) VALUES
  (2, 7, 6, '2026-09-02', '17:00:00', 'Agendada', 220.31, '2026-08-14 08:00:00', 'Paciente relatou melhora'),
  (9, 8, 13, '2026-03-01', '13:30:00', 'Realizada', 275.24, '2026-01-09 18:00:00', NULL),
  (4, 9, 9, '2026-01-17', '13:30:00', 'Faltou', 244.78, '2025-11-25 10:00:00', 'Paciente relatou melhora'),
  (6, 10, 4, '2026-06-14', '09:30:00', 'Realizada', 204.42, '2026-05-15 12:00:00', 'Encaixe de urgencia'),
  (5, 10, 1, '2026-06-11', '14:30:00', 'Faltou', 143.58, '2026-05-03 12:00:00', NULL),
  (19, 11, 1, '2026-08-24', '08:30:00', 'Realizada', 159.43, '2026-07-06 10:00:00', 'Paciente relatou melhora'),
  (2, 10, 4, '2026-09-23', '17:00:00', 'Agendada', 177.66, '2026-09-17 15:00:00', 'Retorno de acompanhamento'),
  (3, 2, 8, '2026-04-19', '16:00:00', 'Cancelada', 227.26, '2026-03-05 15:00:00', NULL),
  (5, 6, 12, '2026-04-16', '09:30:00', 'Realizada', 232.31, '2026-02-25 14:00:00', NULL),
  (7, 9, 13, '2026-06-01', '08:30:00', 'Cancelada', 272.28, '2026-05-19 16:00:00', 'Encaixe de urgencia'),
  (11, 4, 7, '2026-08-10', '10:00:00', 'Faltou', 322.37, '2026-06-11 12:00:00', NULL),
  (1, 11, 6, '2026-01-22', '14:00:00', 'Realizada', 212.36, '2025-12-17 08:00:00', NULL),
  (5, 2, 8, '2026-07-15', '14:00:00', 'Realizada', 204.12, '2026-06-12 12:00:00', 'Encaixe de urgencia'),
  (3, 9, 9, '2026-05-17', '11:00:00', 'Cancelada', 291.16, '2026-03-19 17:00:00', NULL),
  (3, 13, 14, '2026-04-25', '13:30:00', 'Faltou', 263.15, '2026-03-03 08:00:00', 'Encaixe de urgencia'),
  (15, 8, 7, '2026-04-27', '14:30:00', 'Realizada', 339.96, '2026-03-22 16:00:00', NULL),
  (19, 4, 7, '2026-03-01', '16:00:00', 'Realizada', 322.89, '2026-02-26 13:00:00', 'Primeira consulta'),
  (4, 11, 6, '2026-07-13', '08:30:00', 'Realizada', 226.09, '2026-07-04 16:00:00', NULL),
  (15, 8, 13, '2026-07-29', '16:30:00', 'Realizada', 265.92, '2026-07-28 10:00:00', NULL),
  (1, 13, 14, '2026-04-24', '15:30:00', 'Realizada', 300.53, '2026-03-13 09:00:00', 'Primeira consulta'),
  (18, 11, 1, '2026-08-06', '08:30:00', 'Faltou', 160.66, '2026-06-27 09:00:00', 'Paciente relatou melhora'),
  (19, 12, 2, '2026-06-12', '09:30:00', 'Realizada', 259.04, '2026-04-24 18:00:00', NULL),
  (8, 1, 11, '2026-04-17', '08:30:00', 'Realizada', 224.73, '2026-03-29 13:00:00', 'Primeira consulta'),
  (6, 13, 14, '2026-01-28', '10:30:00', 'Realizada', 284.83, '2026-01-22 17:00:00', NULL),
  (5, 10, 1, '2026-02-28', '16:30:00', 'Realizada', 160.01, '2026-01-18 12:00:00', 'Encaixe de urgencia'),
  (16, 11, 6, '2025-12-09', '16:30:00', 'Cancelada', 262.32, '2025-11-16 17:00:00', 'Paciente relatou melhora'),
  (5, 5, 10, '2026-05-17', '17:00:00', 'Realizada', 287.02, '2026-05-10 11:00:00', 'Paciente relatou melhora'),
  (19, 5, 10, '2026-05-23', '13:30:00', 'Realizada', 317.43, '2026-05-22 17:00:00', NULL),
  (16, 12, 2, '2026-03-28', '13:00:00', 'Cancelada', 265.31, '2026-02-17 13:00:00', 'Paciente relatou melhora'),
  (8, 12, 2, '2026-09-19', '09:30:00', 'Agendada', 297.24, '2026-07-23 18:00:00', 'Paciente relatou melhora'),
  (12, 1, 4, '2026-01-08', '09:00:00', 'Cancelada', 180.7, '2025-11-10 12:00:00', NULL),
  (2, 9, 13, '2026-07-31', '13:30:00', 'Faltou', 276.54, '2026-06-07 10:00:00', 'Encaixe de urgencia'),
  (18, 5, 14, '2025-12-30', '16:30:00', 'Realizada', 258.23, '2025-12-25 10:00:00', 'Primeira consulta'),
  (18, 13, 14, '2025-12-18', '15:30:00', 'Realizada', 273.7, '2025-12-17 12:00:00', 'Paciente relatou melhora'),
  (6, 11, 1, '2025-12-27', '13:00:00', 'Realizada', 170.37, '2025-11-26 08:00:00', 'Retorno de acompanhamento'),
  (16, 4, 7, '2026-09-23', '16:30:00', 'Agendada', 318.69, '2026-07-26 12:00:00', NULL),
  (2, 1, 4, '2026-07-12', '09:30:00', 'Realizada', 168.1, '2026-07-05 11:00:00', 'Encaixe de urgencia'),
  (4, 12, 2, '2026-08-29', '10:00:00', 'Realizada', 310.36, '2026-07-03 14:00:00', 'Primeira consulta'),
  (17, 5, 10, '2026-05-10', '11:00:00', 'Realizada', 323.02, '2026-04-11 15:00:00', NULL),
  (19, 6, 12, '2025-12-03', '15:30:00', 'Realizada', 238.82, '2025-11-15 11:00:00', 'Encaixe de urgencia'),
  (1, 4, 7, '2025-11-27', '14:30:00', 'Realizada', 285.39, '2025-11-11 10:00:00', NULL),
  (6, 4, 7, '2026-01-16', '08:00:00', 'Realizada', 310.52, '2025-12-29 10:00:00', NULL),
  (2, 1, 11, '2025-11-09', '15:00:00', 'Realizada', 216.95, '2025-09-19 11:00:00', 'Paciente relatou melhora'),
  (1, 12, 2, '2026-07-29', '09:30:00', 'Realizada', 306.46, '2026-06-11 09:00:00', NULL),
  (5, 4, 7, '2026-07-26', '14:00:00', 'Realizada', 274.56, '2026-06-26 18:00:00', 'Encaixe de urgencia'),
  (14, 7, 5, '2026-07-11', '16:30:00', 'Realizada', 234.27, '2026-07-06 09:00:00', NULL),
  (3, 11, 1, '2026-05-16', '14:00:00', 'Realizada', 138.72, '2026-04-16 16:00:00', NULL),
  (14, 11, 6, '2026-06-10', '16:30:00', 'Realizada', 254.58, '2026-04-14 11:00:00', 'Primeira consulta'),
  (4, 2, 8, '2026-06-08', '14:30:00', 'Realizada', 187.63, '2026-04-26 12:00:00', 'Encaixe de urgencia'),
  (1, 2, 8, '2026-06-11', '09:30:00', 'Realizada', 207.82, '2026-04-24 13:00:00', 'Retorno de acompanhamento'),
  (7, 7, 6, '2026-06-06', '08:30:00', 'Realizada', 212.96, '2026-05-18 17:00:00', NULL),
  (2, 8, 13, '2025-12-27', '15:00:00', 'Cancelada', 272.66, '2025-11-02 16:00:00', NULL),
  (12, 9, 9, '2026-09-09', '13:30:00', 'Agendada', 251.76, '2026-09-07 10:00:00', 'Paciente relatou melhora'),
  (17, 6, 12, '2026-02-02', '10:00:00', 'Realizada', 196.45, '2025-12-27 18:00:00', NULL),
  (1, 9, 9, '2026-05-13', '16:00:00', 'Faltou', 254.26, '2026-04-13 13:00:00', 'Retorno de acompanhamento'),
  (11, 10, 1, '2025-11-28', '10:00:00', 'Faltou', 138.06, '2025-11-17 17:00:00', 'Encaixe de urgencia'),
  (7, 8, 7, '2026-06-02', '13:30:00', 'Faltou', 302.24, '2026-05-19 16:00:00', 'Paciente relatou melhora'),
  (8, 10, 4, '2026-07-29', '14:00:00', 'Realizada', 188.97, '2026-07-26 11:00:00', NULL),
  (2, 4, 7, '2026-03-12', '14:00:00', 'Faltou', 326.03, '2026-02-19 09:00:00', NULL),
  (2, 9, 9, '2026-07-16', '15:00:00', 'Realizada', 236.75, '2026-07-11 14:00:00', NULL),
  (5, 2, 8, '2026-08-23', '16:00:00', 'Realizada', 200.88, '2026-07-17 14:00:00', NULL),
  (4, 6, 12, '2026-09-14', '16:30:00', 'Agendada', 193.63, '2026-07-22 13:00:00', NULL),
  (3, 10, 4, '2026-07-28', '09:00:00', 'Realizada', 171.97, '2026-07-02 12:00:00', NULL),
  (1, 11, 6, '2026-07-31', '11:00:00', 'Faltou', 262.1, '2026-06-03 13:00:00', NULL),
  (3, 3, 3, '2026-02-11', '10:30:00', 'Realizada', 234.05, '2026-01-03 10:00:00', NULL),
  (18, 11, 1, '2026-06-27', '16:30:00', 'Realizada', 171.99, '2026-05-14 17:00:00', 'Retorno de acompanhamento'),
  (14, 11, 1, '2026-01-18', '16:30:00', 'Realizada', 146.36, '2026-01-13 15:00:00', 'Paciente relatou melhora'),
  (6, 6, 12, '2026-04-09', '16:30:00', 'Faltou', 232.66, '2026-03-11 08:00:00', NULL),
  (6, 2, 8, '2026-06-26', '08:30:00', 'Realizada', 196.08, '2026-05-28 17:00:00', 'Encaixe de urgencia'),
  (5, 1, 4, '2025-12-24', '14:30:00', 'Realizada', 169.77, '2025-11-08 09:00:00', NULL),
  (9, 8, 13, '2026-05-07', '15:00:00', 'Cancelada', 273.4, '2026-03-09 12:00:00', NULL),
  (12, 11, 1, '2025-12-05', '14:30:00', 'Realizada', 145.66, '2025-11-28 16:00:00', NULL),
  (4, 10, 1, '2026-04-30', '14:00:00', 'Realizada', 157.31, '2026-03-19 18:00:00', NULL),
  (3, 7, 6, '2026-01-06', '09:00:00', 'Cancelada', 227.81, '2025-11-25 18:00:00', 'Retorno de acompanhamento'),
  (3, 4, 7, '2026-07-08', '11:00:00', 'Faltou', 292.18, '2026-06-23 10:00:00', NULL),
  (5, 9, 9, '2026-04-23', '10:00:00', 'Cancelada', 245.75, '2026-03-15 14:00:00', NULL),
  (9, 1, 4, '2026-05-07', '13:00:00', 'Cancelada', 195.68, '2026-04-08 17:00:00', 'Encaixe de urgencia'),
  (3, 4, 7, '2026-06-30', '11:00:00', 'Realizada', 343.83, '2026-06-06 18:00:00', 'Encaixe de urgencia'),
  (11, 13, 14, '2026-07-17', '16:00:00', 'Realizada', 252.34, '2026-07-06 11:00:00', 'Paciente relatou melhora'),
  (1, 8, 7, '2026-08-12', '09:30:00', 'Realizada', 291.38, '2026-06-27 16:00:00', NULL),
  (3, 9, 9, '2026-06-13', '09:00:00', 'Realizada', 291.5, '2026-04-15 11:00:00', NULL),
  (4, 7, 6, '2026-03-02', '15:30:00', 'Realizada', 225.32, '2026-02-24 13:00:00', NULL),
  (14, 11, 1, '2026-01-15', '10:00:00', 'Realizada', 152.72, '2026-01-12 12:00:00', NULL),
  (11, 8, 7, '2026-09-13', '08:00:00', 'Agendada', 271.43, '2026-07-17 09:00:00', NULL),
  (13, 9, 13, '2025-12-28', '14:00:00', 'Faltou', 239.9, '2025-12-12 12:00:00', 'Encaixe de urgencia'),
  (1, 8, 13, '2026-09-21', '13:00:00', 'Agendada', 243.2, '2026-08-06 10:00:00', NULL),
  (6, 4, 7, '2026-02-05', '09:00:00', 'Faltou', 309.45, '2026-01-02 13:00:00', NULL),
  (4, 8, 13, '2026-09-23', '15:30:00', 'Agendada', 271.71, '2026-08-30 12:00:00', 'Retorno de acompanhamento'),
  (12, 6, 12, '2026-09-19', '09:30:00', 'Agendada', 227.6, '2026-07-31 17:00:00', 'Retorno de acompanhamento'),
  (2, 6, 12, '2026-01-30', '16:30:00', 'Realizada', 231.6, '2025-12-16 15:00:00', NULL),
  (9, 8, 13, '2026-04-01', '11:00:00', 'Realizada', 244.72, '2026-03-29 11:00:00', 'Paciente relatou melhora'),
  (5, 9, 13, '2026-03-11', '08:30:00', 'Faltou', 247.31, '2026-01-21 18:00:00', NULL),
  (15, 6, 12, '2026-01-04', '15:00:00', 'Realizada', 235.97, '2025-12-07 14:00:00', 'Primeira consulta'),
  (4, 3, 3, '2026-07-14', '15:00:00', 'Faltou', 202.54, '2026-05-15 16:00:00', 'Primeira consulta'),
  (1, 10, 1, '2026-08-08', '14:00:00', 'Faltou', 159.78, '2026-07-18 09:00:00', 'Paciente relatou melhora'),
  (5, 12, 2, '2026-01-26', '16:30:00', 'Cancelada', 312.9, '2026-01-03 15:00:00', 'Retorno de acompanhamento'),
  (6, 7, 6, '2025-12-01', '09:00:00', 'Realizada', 236.5, '2025-10-19 18:00:00', NULL),
  (18, 3, 3, '2025-11-19', '10:00:00', 'Realizada', 218.15, '2025-11-14 11:00:00', 'Primeira consulta'),
  (18, 1, 11, '2026-06-20', '15:00:00', 'Realizada', 250.44, '2026-05-27 15:00:00', 'Retorno de acompanhamento'),
  (4, 11, 1, '2026-03-09', '09:30:00', 'Realizada', 149.51, '2026-03-07 10:00:00', NULL),
  (3, 5, 14, '2026-02-19', '14:00:00', 'Faltou', 252.16, '2026-01-05 15:00:00', NULL),
  (5, 12, 2, '2025-12-16', '14:30:00', 'Realizada', 290.5, '2025-11-03 13:00:00', 'Paciente relatou melhora'),
  (15, 3, 3, '2026-05-06', '13:00:00', 'Realizada', 211.02, '2026-04-28 11:00:00', 'Encaixe de urgencia'),
  (1, 9, 13, '2026-06-29', '10:00:00', 'Faltou', 249.88, '2026-05-20 09:00:00', 'Encaixe de urgencia'),
  (5, 13, 14, '2026-08-23', '09:00:00', 'Realizada', 273.37, '2026-08-14 13:00:00', 'Retorno de acompanhamento'),
  (2, 13, 14, '2026-01-07', '16:00:00', 'Realizada', 277.97, '2025-12-05 08:00:00', 'Paciente relatou melhora'),
  (2, 6, 12, '2026-04-28', '14:00:00', 'Cancelada', 222.34, '2026-03-04 09:00:00', 'Paciente relatou melhora'),
  (2, 5, 10, '2026-07-17', '10:30:00', 'Cancelada', 308.76, '2026-06-09 17:00:00', 'Retorno de acompanhamento'),
  (14, 10, 1, '2025-11-16', '09:00:00', 'Realizada', 144.92, '2025-11-13 18:00:00', NULL),
  (11, 7, 5, '2026-07-14', '14:00:00', 'Cancelada', 275.29, '2026-06-02 12:00:00', 'Primeira consulta'),
  (3, 2, 8, '2026-01-21', '16:30:00', 'Realizada', 197.01, '2025-12-25 15:00:00', NULL),
  (3, 12, 2, '2026-04-27', '15:30:00', 'Realizada', 259.43, '2026-04-18 13:00:00', NULL),
  (5, 5, 14, '2026-03-08', '10:00:00', 'Realizada', 268.93, '2026-03-01 08:00:00', 'Primeira consulta'),
  (3, 3, 3, '2026-08-24', '14:30:00', 'Realizada', 226.31, '2026-08-11 10:00:00', 'Encaixe de urgencia'),
  (15, 8, 13, '2025-12-18', '15:30:00', 'Realizada', 238.45, '2025-11-15 15:00:00', 'Retorno de acompanhamento'),
  (1, 5, 14, '2026-09-03', '17:00:00', 'Agendada', 243.55, '2026-08-15 16:00:00', NULL),
  (4, 5, 14, '2026-05-27', '15:00:00', 'Cancelada', 280.92, '2026-05-24 14:00:00', 'Retorno de acompanhamento'),
  (6, 2, 8, '2026-07-18', '16:30:00', 'Cancelada', 229.45, '2026-05-30 16:00:00', NULL),
  (2, 2, 8, '2026-05-12', '14:30:00', 'Realizada', 189.95, '2026-04-06 13:00:00', 'Primeira consulta'),
  (5, 1, 11, '2026-01-11', '14:30:00', 'Realizada', 224.94, '2025-11-20 15:00:00', NULL),
  (4, 10, 4, '2026-01-24', '15:30:00', 'Realizada', 184.83, '2025-12-15 12:00:00', 'Encaixe de urgencia'),
  (9, 5, 14, '2025-11-10', '15:00:00', 'Cancelada', 271.12, '2025-10-19 18:00:00', 'Paciente relatou melhora'),
  (12, 12, 2, '2026-09-03', '17:00:00', 'Agendada', 306.8, '2026-08-17 18:00:00', NULL),
  (9, 10, 4, '2026-01-28', '15:30:00', 'Cancelada', 187.77, '2026-01-18 18:00:00', NULL),
  (2, 8, 7, '2026-06-04', '10:00:00', 'Realizada', 328.12, '2026-05-08 11:00:00', 'Encaixe de urgencia'),
  (15, 12, 2, '2026-01-11', '11:00:00', 'Realizada', 285.49, '2025-12-06 13:00:00', 'Primeira consulta'),
  (3, 3, 3, '2026-08-01', '14:30:00', 'Realizada', 245.72, '2026-06-27 13:00:00', 'Paciente relatou melhora'),
  (6, 4, 7, '2026-03-24', '14:00:00', 'Realizada', 322.87, '2026-03-09 12:00:00', 'Encaixe de urgencia'),
  (3, 6, 12, '2026-03-29', '09:30:00', 'Realizada', 236.03, '2026-02-20 18:00:00', 'Primeira consulta'),
  (13, 13, 14, '2026-03-30', '08:30:00', 'Realizada', 272.86, '2026-03-11 09:00:00', 'Paciente relatou melhora'),
  (10, 4, 7, '2026-08-04', '13:30:00', 'Realizada', 280.3, '2026-06-05 16:00:00', NULL),
  (3, 11, 6, '2026-03-01', '08:30:00', 'Realizada', 234.16, '2026-02-22 14:00:00', NULL),
  (1, 9, 9, '2026-05-29', '17:00:00', 'Faltou', 296.65, '2026-04-28 18:00:00', 'Retorno de acompanhamento'),
  (3, 1, 11, '2026-08-22', '13:00:00', 'Realizada', 226.5, '2026-07-18 08:00:00', NULL),
  (17, 1, 4, '2026-07-13', '10:30:00', 'Realizada', 162.42, '2026-05-14 12:00:00', NULL),
  (17, 6, 12, '2026-06-22', '17:00:00', 'Realizada', 213.57, '2026-04-26 10:00:00', NULL),
  (12, 6, 12, '2026-06-24', '13:30:00', 'Faltou', 206.7, '2026-05-09 10:00:00', 'Paciente relatou melhora'),
  (6, 13, 14, '2026-01-30', '15:30:00', 'Realizada', 248.85, '2025-12-08 14:00:00', NULL),
  (2, 3, 3, '2026-04-16', '13:00:00', 'Realizada', 222.57, '2026-04-15 12:00:00', 'Paciente relatou melhora'),
  (18, 5, 10, '2026-03-15', '15:00:00', 'Faltou', 269.57, '2026-01-29 11:00:00', 'Paciente relatou melhora'),
  (2, 11, 1, '2026-01-01', '14:00:00', 'Cancelada', 170.9, '2025-12-08 17:00:00', 'Encaixe de urgencia'),
  (2, 12, 2, '2026-06-02', '17:00:00', 'Realizada', 309.79, '2026-04-14 16:00:00', NULL),
  (8, 10, 1, '2026-07-29', '16:30:00', 'Faltou', 156.16, '2026-06-25 13:00:00', NULL),
  (13, 9, 9, '2026-08-22', '10:00:00', 'Realizada', 262.72, '2026-08-11 13:00:00', NULL),
  (9, 8, 13, '2026-07-21', '16:30:00', 'Realizada', 257.08, '2026-05-30 08:00:00', 'Encaixe de urgencia'),
  (6, 9, 13, '2026-04-08', '08:00:00', 'Realizada', 271.61, '2026-03-13 12:00:00', NULL),
  (1, 6, 12, '2026-08-06', '08:30:00', 'Realizada', 213.78, '2026-06-07 09:00:00', 'Paciente relatou melhora'),
  (4, 13, 14, '2026-06-05', '15:00:00', 'Realizada', 304.91, '2026-04-08 14:00:00', 'Primeira consulta'),
  (4, 11, 6, '2026-04-29', '09:30:00', 'Realizada', 214.32, '2026-04-17 16:00:00', NULL),
  (13, 13, 14, '2026-04-03', '16:30:00', 'Realizada', 268.6, '2026-02-18 16:00:00', NULL),
  (3, 6, 12, '2026-03-23', '11:00:00', 'Faltou', 223.66, '2026-01-22 09:00:00', NULL),
  (3, 2, 8, '2026-09-02', '08:30:00', 'Agendada', 213.6, '2026-08-04 17:00:00', NULL),
  (3, 1, 4, '2026-06-14', '13:00:00', 'Realizada', 196.92, '2026-05-10 11:00:00', NULL),
  (5, 5, 10, '2026-08-23', '14:30:00', 'Realizada', 320.33, '2026-07-17 17:00:00', NULL),
  (3, 3, 3, '2026-06-01', '14:00:00', 'Realizada', 230.54, '2026-05-14 08:00:00', NULL),
  (6, 7, 6, '2025-11-26', '15:00:00', 'Realizada', 237.16, '2025-10-15 18:00:00', 'Primeira consulta'),
  (4, 5, 14, '2026-02-04', '17:00:00', 'Realizada', 290.76, '2026-01-19 11:00:00', 'Encaixe de urgencia'),
  (16, 9, 13, '2026-06-03', '10:00:00', 'Faltou', 245.64, '2026-05-09 11:00:00', NULL),
  (17, 6, 12, '2026-08-03', '11:00:00', 'Realizada', 220.76, '2026-07-30 12:00:00', NULL),
  (15, 4, 7, '2026-07-05', '11:00:00', 'Cancelada', 338.17, '2026-05-10 13:00:00', NULL),
  (17, 12, 2, '2026-07-05', '13:00:00', 'Realizada', 279.76, '2026-05-21 17:00:00', NULL),
  (6, 13, 14, '2026-05-15', '16:30:00', 'Realizada', 260.66, '2026-04-10 18:00:00', 'Encaixe de urgencia'),
  (5, 13, 14, '2026-04-14', '11:00:00', 'Realizada', 280.97, '2026-03-21 13:00:00', NULL),
  (10, 1, 4, '2026-08-12', '16:00:00', 'Faltou', 172.35, '2026-07-24 10:00:00', NULL),
  (5, 11, 1, '2026-03-13', '17:00:00', 'Realizada', 152.28, '2026-01-25 18:00:00', 'Retorno de acompanhamento');

-- ============================================================
-- Inserção de dados — prontuarios
-- ============================================================

INSERT INTO prontuarios (id_paciente, data_abertura, tipo_sanguineo, alergias_conhecidas, historico_familiar_relevante, observacoes_gerais, data_ultima_atualizacao) VALUES
  (1, '2025-08-18', 'A+', 'Latex', NULL, NULL, '2026-08-29 00:00:00'),
  (2, '2023-07-16', 'O+', NULL, 'Asma', NULL, '2026-08-29 00:00:00'),
  (3, '2026-02-28', 'O+', NULL, 'Diabetes tipo 2', NULL, '2026-08-29 00:00:00'),
  (4, '2025-10-22', 'A-', NULL, 'Cancer de mama', NULL, '2026-08-29 00:00:00'),
  (5, '2025-09-24', 'O+', 'Dipirona', 'Doencas cardiacas', NULL, '2026-08-29 00:00:00'),
  (6, '2024-01-09', 'B-', NULL, 'Doencas cardiacas', NULL, '2026-08-29 00:00:00'),
  (7, '2023-01-01', 'AB-', 'Latex', NULL, NULL, '2026-08-29 00:00:00'),
  (8, '2026-07-17', 'AB+', NULL, NULL, NULL, '2026-08-29 00:00:00'),
  (9, '2023-08-11', 'B+', 'Penicilina', NULL, NULL, '2026-08-29 00:00:00'),
  (10, '2023-10-06', 'AB+', NULL, NULL, NULL, '2026-08-29 00:00:00'),
  (11, '2026-01-14', 'A+', 'Dipirona', NULL, NULL, '2026-08-29 00:00:00'),
  (12, '2023-02-07', 'B+', 'Poeira e acaros', 'Hipertensao', NULL, '2026-08-29 00:00:00'),
  (13, '2024-05-09', 'O-', 'Poeira e acaros', 'Diabetes tipo 2', NULL, '2026-08-29 00:00:00'),
  (14, '2024-01-02', 'A-', 'Dipirona', 'Hipertensao', NULL, '2026-08-29 00:00:00'),
  (15, '2022-09-29', 'O-', NULL, NULL, NULL, '2026-08-29 00:00:00'),
  (16, '2024-04-21', 'AB+', 'Frutos do mar', 'Doencas cardiacas', NULL, '2026-08-29 00:00:00'),
  (17, '2023-11-29', 'O+', NULL, 'Cancer de mama', NULL, '2026-08-29 00:00:00'),
  (18, '2025-08-14', 'O-', 'Latex', 'Asma', NULL, '2026-08-29 00:00:00'),
  (19, '2024-02-23', 'B-', NULL, 'Doencas cardiacas', NULL, '2026-08-29 00:00:00');

-- ============================================================
-- Inserção de dados — evolucoes
-- ============================================================

INSERT INTO evolucoes (id_consulta, data_registro, queixa_principal, diagnostico, anotacoes_medico, cid, conduta) VALUES
  (2, '2026-03-01 08:00:00', 'Dor nas costas', 'Sintomas controlados com medicacao', 'Paciente atendido conforme protocolo padrao da especialidade.', 'I10', 'Orientacoes gerais e acompanhamento'),
  (4, '2026-06-14 08:00:00', 'Dor abdominal', 'Condicao cronica em acompanhamento', 'Paciente atendido conforme protocolo padrao da especialidade.', 'J06.9', 'Retorno em 15 dias para reavaliacao'),
  (6, '2026-08-24 17:00:00', 'Dor no peito leve', 'Quadro compativel com condicao leve, sem gravidade', 'Paciente atendido conforme protocolo padrao da especialidade.', 'R51', 'Orientacoes gerais e acompanhamento'),
  (9, '2026-04-16 08:00:00', 'Dor nas costas', 'Suspeita de origem viral', 'Paciente atendido conforme protocolo padrao da especialidade.', 'R51', 'Alta do quadro atual, retorno se necessario'),
  (12, '2026-01-22 14:00:00', 'Dor abdominal', 'Necessario acompanhamento continuo', 'Paciente atendido conforme protocolo padrao da especialidade.', 'R51', 'Retorno em 15 dias para reavaliacao'),
  (13, '2026-07-15 11:00:00', 'Check-up de rotina', 'Sem alteracoes significativas no exame', 'Paciente atendido conforme protocolo padrao da especialidade.', 'F41.1', 'Alta do quadro atual, retorno se necessario'),
  (16, '2026-04-27 16:00:00', 'Tontura ocasional', 'Quadro estavel, sem alteracoes relevantes', 'Paciente atendido conforme protocolo padrao da especialidade.', 'R51', 'Alta do quadro atual, retorno se necessario'),
  (17, '2026-03-01 09:00:00', 'Cansaco excessivo', 'Condicao cronica em acompanhamento', 'Paciente atendido conforme protocolo padrao da especialidade.', 'K29.7', 'Prescricao de medicamento e retorno em 30 dias'),
  (18, '2026-07-13 09:00:00', 'Coceira na pele', 'Sintomas controlados com medicacao', 'Paciente atendido conforme protocolo padrao da especialidade.', NULL, 'Orientacoes gerais e acompanhamento'),
  (19, '2026-07-29 17:00:00', 'Alergia respiratoria', 'Suspeita de origem viral', 'Paciente atendido conforme protocolo padrao da especialidade.', 'F41.1', 'Orientacoes gerais e acompanhamento'),
  (20, '2026-04-24 08:00:00', 'Dor no peito leve', 'Necessario acompanhamento continuo', 'Paciente atendido conforme protocolo padrao da especialidade.', 'I10', 'Solicitado exame de sangue'),
  (22, '2026-06-12 11:00:00', 'Tontura ocasional', 'Suspeita de origem viral', 'Paciente atendido conforme protocolo padrao da especialidade.', 'F41.1', 'Solicitado exame de sangue'),
  (23, '2026-04-17 10:00:00', 'Dor no peito leve', 'Suspeita de origem viral', 'Paciente atendido conforme protocolo padrao da especialidade.', 'F41.1', 'Prescricao de medicamento e retorno em 30 dias'),
  (24, '2026-01-28 17:00:00', 'Falta de ar leve', 'Sem alteracoes significativas no exame', 'Paciente atendido conforme protocolo padrao da especialidade.', 'M54.5', 'Alta do quadro atual, retorno se necessario'),
  (25, '2026-02-28 09:00:00', 'Dor abdominal', 'Necessario acompanhamento continuo', 'Paciente atendido conforme protocolo padrao da especialidade.', 'R51', 'Solicitado exame de sangue'),
  (27, '2026-05-17 18:00:00', 'Febre e mal-estar', 'Condicao cronica em acompanhamento', 'Paciente atendido conforme protocolo padrao da especialidade.', 'F41.1', 'Orientacoes gerais e acompanhamento'),
  (28, '2026-05-23 13:00:00', 'Dor abdominal', 'Quadro compativel com condicao leve, sem gravidade', 'Paciente atendido conforme protocolo padrao da especialidade.', NULL, 'Orientacoes gerais e acompanhamento'),
  (33, '2025-12-30 15:00:00', 'Tontura ocasional', 'Sem alteracoes significativas no exame', 'Paciente atendido conforme protocolo padrao da especialidade.', 'J06.9', 'Prescricao de medicamento e retorno em 30 dias'),
  (34, '2025-12-18 10:00:00', 'Dor abdominal', 'Sintomas controlados com medicacao', 'Paciente atendido conforme protocolo padrao da especialidade.', 'F41.1', 'Solicitado exame de sangue'),
  (35, '2025-12-27 16:00:00', 'Cansaco excessivo', 'Suspeita de origem viral', 'Paciente atendido conforme protocolo padrao da especialidade.', 'F41.1', 'Prescricao de medicamento e retorno em 30 dias'),
  (37, '2026-07-12 08:00:00', 'Dor abdominal', 'Necessario acompanhamento continuo', 'Paciente atendido conforme protocolo padrao da especialidade.', NULL, 'Retorno em 15 dias para reavaliacao'),
  (38, '2026-08-29 17:00:00', 'Alergia respiratoria', 'Necessario acompanhamento continuo', 'Paciente atendido conforme protocolo padrao da especialidade.', 'F41.1', 'Prescricao de medicamento e retorno em 30 dias'),
  (39, '2026-05-10 12:00:00', 'Coceira na pele', 'Quadro estavel, sem alteracoes relevantes', 'Paciente atendido conforme protocolo padrao da especialidade.', NULL, 'Alta do quadro atual, retorno se necessario'),
  (40, '2025-12-03 16:00:00', 'Dor nas costas', 'Suspeita de origem viral', 'Paciente atendido conforme protocolo padrao da especialidade.', 'R51', 'Alta do quadro atual, retorno se necessario'),
  (41, '2025-11-27 14:00:00', 'Febre e mal-estar', 'Sintomas controlados com medicacao', 'Paciente atendido conforme protocolo padrao da especialidade.', 'J06.9', 'Orientacoes gerais e acompanhamento'),
  (42, '2026-01-16 12:00:00', 'Dor articular', 'Sintomas controlados com medicacao', 'Paciente atendido conforme protocolo padrao da especialidade.', NULL, 'Encaminhado para exames complementares'),
  (43, '2025-11-09 14:00:00', 'Falta de ar leve', 'Quadro estavel, sem alteracoes relevantes', 'Paciente atendido conforme protocolo padrao da especialidade.', 'J06.9', 'Solicitado exame de sangue'),
  (44, '2026-07-29 09:00:00', 'Tontura ocasional', 'Necessario acompanhamento continuo', 'Paciente atendido conforme protocolo padrao da especialidade.', 'M54.5', 'Alta do quadro atual, retorno se necessario'),
  (45, '2026-07-26 18:00:00', 'Dor articular', 'Suspeita de origem viral', 'Paciente atendido conforme protocolo padrao da especialidade.', 'M54.5', 'Solicitado exame de sangue'),
  (46, '2026-07-11 09:00:00', 'Febre e mal-estar', 'Necessario acompanhamento continuo', 'Paciente atendido conforme protocolo padrao da especialidade.', NULL, 'Solicitado exame de sangue'),
  (47, '2026-05-16 13:00:00', 'Dor de garganta', 'Suspeita de origem viral', 'Paciente atendido conforme protocolo padrao da especialidade.', 'F41.1', 'Orientacoes gerais e acompanhamento'),
  (48, '2026-06-10 15:00:00', 'Tontura ocasional', 'Quadro estavel, sem alteracoes relevantes', 'Paciente atendido conforme protocolo padrao da especialidade.', 'R51', 'Orientacoes gerais e acompanhamento'),
  (49, '2026-06-08 13:00:00', 'Check-up de rotina', 'Condicao cronica em acompanhamento', 'Paciente atendido conforme protocolo padrao da especialidade.', 'M54.5', 'Solicitado exame de sangue'),
  (50, '2026-06-11 13:00:00', 'Febre e mal-estar', 'Quadro estavel, sem alteracoes relevantes', 'Paciente atendido conforme protocolo padrao da especialidade.', 'K29.7', 'Orientacoes gerais e acompanhamento'),
  (51, '2026-06-06 18:00:00', 'Dor articular', 'Suspeita de origem viral', 'Paciente atendido conforme protocolo padrao da especialidade.', 'M54.5', 'Orientacoes gerais e acompanhamento'),
  (54, '2026-02-02 14:00:00', 'Falta de ar leve', 'Sem alteracoes significativas no exame', 'Paciente atendido conforme protocolo padrao da especialidade.', 'F41.1', 'Orientacoes gerais e acompanhamento'),
  (58, '2026-07-29 09:00:00', 'Check-up de rotina', 'Sintomas controlados com medicacao', 'Paciente atendido conforme protocolo padrao da especialidade.', 'R51', 'Alta do quadro atual, retorno se necessario'),
  (60, '2026-07-16 16:00:00', 'Dor de cabeca recorrente', 'Condicao cronica em acompanhamento', 'Paciente atendido conforme protocolo padrao da especialidade.', 'I10', 'Alta do quadro atual, retorno se necessario'),
  (61, '2026-08-23 11:00:00', 'Dor articular', 'Sem alteracoes significativas no exame', 'Paciente atendido conforme protocolo padrao da especialidade.', 'J06.9', 'Alta do quadro atual, retorno se necessario'),
  (63, '2026-07-28 09:00:00', 'Dor de garganta', 'Sem alteracoes significativas no exame', 'Paciente atendido conforme protocolo padrao da especialidade.', 'F41.1', 'Alta do quadro atual, retorno se necessario'),
  (65, '2026-02-11 15:00:00', 'Febre e mal-estar', 'Condicao cronica em acompanhamento', 'Paciente atendido conforme protocolo padrao da especialidade.', 'J06.9', 'Encaminhado para exames complementares'),
  (66, '2026-06-27 12:00:00', 'Dor no peito leve', 'Sintomas controlados com medicacao', 'Paciente atendido conforme protocolo padrao da especialidade.', 'F41.1', 'Solicitado exame de sangue'),
  (67, '2026-01-18 09:00:00', 'Dor articular', 'Suspeita de origem viral', 'Paciente atendido conforme protocolo padrao da especialidade.', 'I10', 'Retorno em 15 dias para reavaliacao'),
  (69, '2026-06-26 14:00:00', 'Cansaco excessivo', 'Suspeita de origem viral', 'Paciente atendido conforme protocolo padrao da especialidade.', 'F41.1', 'Retorno em 15 dias para reavaliacao'),
  (70, '2025-12-24 08:00:00', 'Alergia respiratoria', 'Necessario acompanhamento continuo', 'Paciente atendido conforme protocolo padrao da especialidade.', NULL, 'Prescricao de medicamento e retorno em 30 dias'),
  (72, '2025-12-05 11:00:00', 'Dor no peito leve', 'Condicao cronica em acompanhamento', 'Paciente atendido conforme protocolo padrao da especialidade.', 'K29.7', 'Encaminhado para exames complementares'),
  (73, '2026-04-30 18:00:00', 'Check-up de rotina', 'Quadro compativel com condicao leve, sem gravidade', 'Paciente atendido conforme protocolo padrao da especialidade.', 'F41.1', 'Orientacoes gerais e acompanhamento'),
  (78, '2026-06-30 14:00:00', 'Dor abdominal', 'Quadro compativel com condicao leve, sem gravidade', 'Paciente atendido conforme protocolo padrao da especialidade.', NULL, 'Orientacoes gerais e acompanhamento'),
  (79, '2026-07-17 11:00:00', 'Cansaco excessivo', 'Condicao cronica em acompanhamento', 'Paciente atendido conforme protocolo padrao da especialidade.', 'M54.5', 'Solicitado exame de sangue'),
  (80, '2026-08-12 13:00:00', 'Coceira na pele', 'Quadro estavel, sem alteracoes relevantes', 'Paciente atendido conforme protocolo padrao da especialidade.', 'R51', 'Orientacoes gerais e acompanhamento'),
  (81, '2026-06-13 08:00:00', 'Dor articular', 'Quadro compativel com condicao leve, sem gravidade', 'Paciente atendido conforme protocolo padrao da especialidade.', 'J06.9', 'Solicitado exame de sangue'),
  (82, '2026-03-02 09:00:00', 'Dor abdominal', 'Sem alteracoes significativas no exame', 'Paciente atendido conforme protocolo padrao da especialidade.', 'R51', 'Orientacoes gerais e acompanhamento'),
  (83, '2026-01-15 12:00:00', 'Tontura ocasional', 'Quadro estavel, sem alteracoes relevantes', 'Paciente atendido conforme protocolo padrao da especialidade.', 'M54.5', 'Retorno em 15 dias para reavaliacao'),
  (90, '2026-01-30 15:00:00', 'Tontura ocasional', 'Quadro estavel, sem alteracoes relevantes', 'Paciente atendido conforme protocolo padrao da especialidade.', NULL, 'Solicitado exame de sangue'),
  (91, '2026-04-01 15:00:00', 'Tontura ocasional', 'Quadro compativel com condicao leve, sem gravidade', 'Paciente atendido conforme protocolo padrao da especialidade.', 'J06.9', 'Prescricao de medicamento e retorno em 30 dias'),
  (93, '2026-01-04 09:00:00', 'Dor de cabeca recorrente', 'Sem alteracoes significativas no exame', 'Paciente atendido conforme protocolo padrao da especialidade.', 'K29.7', 'Alta do quadro atual, retorno se necessario'),
  (97, '2025-12-01 09:00:00', 'Dor no peito leve', 'Sem alteracoes significativas no exame', 'Paciente atendido conforme protocolo padrao da especialidade.', 'R51', 'Alta do quadro atual, retorno se necessario'),
  (98, '2025-11-19 11:00:00', 'Cansaco excessivo', 'Sintomas controlados com medicacao', 'Paciente atendido conforme protocolo padrao da especialidade.', 'R51', 'Orientacoes gerais e acompanhamento'),
  (99, '2026-06-20 16:00:00', 'Coceira na pele', 'Quadro estavel, sem alteracoes relevantes', 'Paciente atendido conforme protocolo padrao da especialidade.', 'M54.5', 'Solicitado exame de sangue'),
  (100, '2026-03-09 18:00:00', 'Febre e mal-estar', 'Sintomas controlados com medicacao', 'Paciente atendido conforme protocolo padrao da especialidade.', 'F41.1', 'Solicitado exame de sangue'),
  (102, '2025-12-16 08:00:00', 'Ansiedade e insonia', 'Suspeita de origem viral', 'Paciente atendido conforme protocolo padrao da especialidade.', 'M54.5', 'Solicitado exame de sangue'),
  (103, '2026-05-06 17:00:00', 'Coceira na pele', 'Quadro estavel, sem alteracoes relevantes', 'Paciente atendido conforme protocolo padrao da especialidade.', NULL, 'Alta do quadro atual, retorno se necessario'),
  (105, '2026-08-23 11:00:00', 'Dor nas costas', 'Necessario acompanhamento continuo', 'Paciente atendido conforme protocolo padrao da especialidade.', NULL, 'Retorno em 15 dias para reavaliacao'),
  (106, '2026-01-07 09:00:00', 'Alergia respiratoria', 'Sem alteracoes significativas no exame', 'Paciente atendido conforme protocolo padrao da especialidade.', 'R51', 'Orientacoes gerais e acompanhamento'),
  (109, '2025-11-16 13:00:00', 'Dor nas costas', 'Quadro estavel, sem alteracoes relevantes', 'Paciente atendido conforme protocolo padrao da especialidade.', NULL, 'Orientacoes gerais e acompanhamento'),
  (111, '2026-01-21 18:00:00', 'Dor de garganta', 'Quadro estavel, sem alteracoes relevantes', 'Paciente atendido conforme protocolo padrao da especialidade.', 'K29.7', 'Retorno em 15 dias para reavaliacao'),
  (112, '2026-04-27 14:00:00', 'Check-up de rotina', 'Quadro estavel, sem alteracoes relevantes', 'Paciente atendido conforme protocolo padrao da especialidade.', NULL, 'Orientacoes gerais e acompanhamento'),
  (113, '2026-03-08 13:00:00', 'Dor de garganta', 'Quadro estavel, sem alteracoes relevantes', 'Paciente atendido conforme protocolo padrao da especialidade.', 'R51', 'Alta do quadro atual, retorno se necessario'),
  (114, '2026-08-24 12:00:00', 'Check-up de rotina', 'Suspeita de origem viral', 'Paciente atendido conforme protocolo padrao da especialidade.', NULL, 'Alta do quadro atual, retorno se necessario'),
  (115, '2025-12-18 10:00:00', 'Tontura ocasional', 'Quadro compativel com condicao leve, sem gravidade', 'Paciente atendido conforme protocolo padrao da especialidade.', 'M54.5', 'Orientacoes gerais e acompanhamento'),
  (119, '2026-05-12 09:00:00', 'Febre e mal-estar', 'Necessario acompanhamento continuo', 'Paciente atendido conforme protocolo padrao da especialidade.', 'R51', 'Retorno em 15 dias para reavaliacao'),
  (120, '2026-01-11 14:00:00', 'Coceira na pele', 'Suspeita de origem viral', 'Paciente atendido conforme protocolo padrao da especialidade.', 'R51', 'Retorno em 15 dias para reavaliacao'),
  (121, '2026-01-24 14:00:00', 'Coceira na pele', 'Sintomas controlados com medicacao', 'Paciente atendido conforme protocolo padrao da especialidade.', 'I10', 'Alta do quadro atual, retorno se necessario'),
  (125, '2026-06-04 16:00:00', 'Ansiedade e insonia', 'Condicao cronica em acompanhamento', 'Paciente atendido conforme protocolo padrao da especialidade.', 'R51', 'Retorno em 15 dias para reavaliacao'),
  (126, '2026-01-11 10:00:00', 'Dor articular', 'Necessario acompanhamento continuo', 'Paciente atendido conforme protocolo padrao da especialidade.', 'R51', 'Encaminhado para exames complementares'),
  (127, '2026-08-01 13:00:00', 'Dor de garganta', 'Quadro estavel, sem alteracoes relevantes', 'Paciente atendido conforme protocolo padrao da especialidade.', NULL, 'Orientacoes gerais e acompanhamento'),
  (128, '2026-03-24 08:00:00', 'Dor articular', 'Sintomas controlados com medicacao', 'Paciente atendido conforme protocolo padrao da especialidade.', 'M54.5', 'Solicitado exame de sangue'),
  (129, '2026-03-29 16:00:00', 'Cansaco excessivo', 'Condicao cronica em acompanhamento', 'Paciente atendido conforme protocolo padrao da especialidade.', 'I10', 'Solicitado exame de sangue'),
  (130, '2026-03-30 18:00:00', 'Dor articular', 'Quadro estavel, sem alteracoes relevantes', 'Paciente atendido conforme protocolo padrao da especialidade.', 'I10', 'Solicitado exame de sangue'),
  (131, '2026-08-04 10:00:00', 'Dor abdominal', 'Suspeita de origem viral', 'Paciente atendido conforme protocolo padrao da especialidade.', NULL, 'Encaminhado para exames complementares'),
  (132, '2026-03-01 12:00:00', 'Dor de cabeca recorrente', 'Necessario acompanhamento continuo', 'Paciente atendido conforme protocolo padrao da especialidade.', 'M54.5', 'Retorno em 15 dias para reavaliacao'),
  (134, '2026-08-22 12:00:00', 'Febre e mal-estar', 'Sem alteracoes significativas no exame', 'Paciente atendido conforme protocolo padrao da especialidade.', 'I10', 'Retorno em 15 dias para reavaliacao'),
  (135, '2026-07-13 15:00:00', 'Cansaco excessivo', 'Suspeita de origem viral', 'Paciente atendido conforme protocolo padrao da especialidade.', NULL, 'Retorno em 15 dias para reavaliacao'),
  (136, '2026-06-22 09:00:00', 'Falta de ar leve', 'Sem alteracoes significativas no exame', 'Paciente atendido conforme protocolo padrao da especialidade.', 'K29.7', 'Retorno em 15 dias para reavaliacao'),
  (138, '2026-01-30 08:00:00', 'Alergia respiratoria', 'Condicao cronica em acompanhamento', 'Paciente atendido conforme protocolo padrao da especialidade.', 'I10', 'Retorno em 15 dias para reavaliacao'),
  (139, '2026-04-16 11:00:00', 'Coceira na pele', 'Quadro compativel com condicao leve, sem gravidade', 'Paciente atendido conforme protocolo padrao da especialidade.', 'M54.5', 'Orientacoes gerais e acompanhamento'),
  (142, '2026-06-02 08:00:00', 'Dor articular', 'Necessario acompanhamento continuo', 'Paciente atendido conforme protocolo padrao da especialidade.', 'K29.7', 'Prescricao de medicamento e retorno em 30 dias'),
  (144, '2026-08-22 15:00:00', 'Dor de garganta', 'Quadro compativel com condicao leve, sem gravidade', 'Paciente atendido conforme protocolo padrao da especialidade.', 'M54.5', 'Encaminhado para exames complementares'),
  (145, '2026-07-21 17:00:00', 'Ansiedade e insonia', 'Necessario acompanhamento continuo', 'Paciente atendido conforme protocolo padrao da especialidade.', 'F41.1', 'Encaminhado para exames complementares'),
  (146, '2026-04-08 17:00:00', 'Febre e mal-estar', 'Sem alteracoes significativas no exame', 'Paciente atendido conforme protocolo padrao da especialidade.', 'M54.5', 'Encaminhado para exames complementares'),
  (147, '2026-08-06 08:00:00', 'Check-up de rotina', 'Necessario acompanhamento continuo', 'Paciente atendido conforme protocolo padrao da especialidade.', 'J06.9', 'Retorno em 15 dias para reavaliacao'),
  (148, '2026-06-05 16:00:00', 'Febre e mal-estar', 'Necessario acompanhamento continuo', 'Paciente atendido conforme protocolo padrao da especialidade.', 'J06.9', 'Orientacoes gerais e acompanhamento'),
  (149, '2026-04-29 17:00:00', 'Falta de ar leve', 'Sem alteracoes significativas no exame', 'Paciente atendido conforme protocolo padrao da especialidade.', NULL, 'Encaminhado para exames complementares'),
  (150, '2026-04-03 14:00:00', 'Dor de cabeca recorrente', 'Necessario acompanhamento continuo', 'Paciente atendido conforme protocolo padrao da especialidade.', 'R51', 'Alta do quadro atual, retorno se necessario'),
  (153, '2026-06-14 10:00:00', 'Dor nas costas', 'Sintomas controlados com medicacao', 'Paciente atendido conforme protocolo padrao da especialidade.', 'K29.7', 'Encaminhado para exames complementares'),
  (154, '2026-08-23 18:00:00', 'Coceira na pele', 'Quadro estavel, sem alteracoes relevantes', 'Paciente atendido conforme protocolo padrao da especialidade.', 'R51', 'Retorno em 15 dias para reavaliacao'),
  (155, '2026-06-01 18:00:00', 'Falta de ar leve', 'Condicao cronica em acompanhamento', 'Paciente atendido conforme protocolo padrao da especialidade.', 'F41.1', 'Solicitado exame de sangue'),
  (156, '2025-11-26 15:00:00', 'Dor abdominal', 'Condicao cronica em acompanhamento', 'Paciente atendido conforme protocolo padrao da especialidade.', NULL, 'Solicitado exame de sangue'),
  (157, '2026-02-04 16:00:00', 'Ansiedade e insonia', 'Necessario acompanhamento continuo', 'Paciente atendido conforme protocolo padrao da especialidade.', 'K29.7', 'Solicitado exame de sangue'),
  (159, '2026-08-03 15:00:00', 'Tontura ocasional', 'Suspeita de origem viral', 'Paciente atendido conforme protocolo padrao da especialidade.', NULL, 'Alta do quadro atual, retorno se necessario'),
  (161, '2026-07-05 09:00:00', 'Ansiedade e insonia', 'Quadro estavel, sem alteracoes relevantes', 'Paciente atendido conforme protocolo padrao da especialidade.', 'K29.7', 'Prescricao de medicamento e retorno em 30 dias'),
  (162, '2026-05-15 16:00:00', 'Coceira na pele', 'Sintomas controlados com medicacao', 'Paciente atendido conforme protocolo padrao da especialidade.', 'F41.1', 'Encaminhado para exames complementares'),
  (163, '2026-04-14 15:00:00', 'Falta de ar leve', 'Necessario acompanhamento continuo', 'Paciente atendido conforme protocolo padrao da especialidade.', 'J06.9', 'Orientacoes gerais e acompanhamento'),
  (165, '2026-03-13 16:00:00', 'Check-up de rotina', 'Sintomas controlados com medicacao', 'Paciente atendido conforme protocolo padrao da especialidade.', 'I10', 'Orientacoes gerais e acompanhamento');

-- ============================================================
-- Inserção de dados — prescricoes
-- ============================================================

INSERT INTO prescricoes (id_evolucao, medicamento, dosagem, posologia, quantidade, duracao_tratamento_dias, data_prescricao, observacoes) VALUES
  (1, 'Dipirona 500mg', 'conforme bula', '1 comprimido a cada 6 horas', 10, 15, '2026-03-01', NULL),
  (3, 'Sinvastatina 20mg', 'conforme bula', '1 comprimido a noite', 60, 5, '2026-08-24', NULL),
  (4, 'Omeprazol 20mg', 'conforme bula', '1 capsula em jejum', 20, 10, '2026-04-16', NULL),
  (6, 'Paracetamol 750mg', 'conforme bula', '1 comprimido a cada 8 horas', 30, 10, '2026-07-15', NULL),
  (8, 'Ibuprofeno 600mg', 'conforme bula', '1 comprimido a cada 12 horas', 10, 15, '2026-03-01', NULL),
  (8, 'Losartana 50mg', 'conforme bula', '1 comprimido pela manha', 20, 15, '2026-03-01', NULL),
  (9, 'Paracetamol 750mg', 'conforme bula', '1 comprimido a cada 8 horas', 10, 7, '2026-07-13', NULL),
  (9, 'Sinvastatina 20mg', 'conforme bula', '1 comprimido a noite', 10, 7, '2026-07-13', NULL),
  (10, 'Sinvastatina 20mg', 'conforme bula', '1 comprimido a noite', 10, 5, '2026-07-29', NULL),
  (10, 'Amoxicilina 500mg', 'conforme bula', '1 capsula a cada 8 horas', 10, 15, '2026-07-29', NULL),
  (11, 'Paracetamol 750mg', 'conforme bula', '1 comprimido a cada 8 horas', 20, 15, '2026-04-24', NULL),
  (13, 'Amoxicilina 500mg', 'conforme bula', '1 capsula a cada 8 horas', 30, 10, '2026-04-17', NULL),
  (15, 'Ibuprofeno 600mg', 'conforme bula', '1 comprimido a cada 12 horas', 10, 30, '2026-02-28', NULL),
  (16, 'Ibuprofeno 600mg', 'conforme bula', '1 comprimido a cada 12 horas', 60, 10, '2026-05-17', NULL),
  (16, 'Omeprazol 20mg', 'conforme bula', '1 capsula em jejum', 20, 15, '2026-05-17', NULL),
  (17, 'Omeprazol 20mg', 'conforme bula', '1 capsula em jejum', 10, 5, '2026-05-23', NULL),
  (20, 'Loratadina 10mg', 'conforme bula', '1 comprimido ao dia', 30, 7, '2025-12-27', NULL),
  (22, 'Metformina 850mg', 'conforme bula', '1 comprimido apos o almoco', 30, 5, '2026-08-29', NULL),
  (23, 'Losartana 50mg', 'conforme bula', '1 comprimido pela manha', 20, 30, '2026-05-10', NULL),
  (23, 'Diazepam 5mg', 'conforme bula', '1 comprimido antes de dormir', 20, 15, '2026-05-10', NULL),
  (26, 'Sinvastatina 20mg', 'conforme bula', '1 comprimido a noite', 60, 5, '2026-01-16', NULL),
  (28, 'Metformina 850mg', 'conforme bula', '1 comprimido apos o almoco', 10, 10, '2026-07-29', NULL),
  (29, 'Loratadina 10mg', 'conforme bula', '1 comprimido ao dia', 60, 10, '2026-07-26', NULL),
  (30, 'Sinvastatina 20mg', 'conforme bula', '1 comprimido a noite', 10, 5, '2026-07-11', NULL),
  (31, 'Losartana 50mg', 'conforme bula', '1 comprimido pela manha', 20, 5, '2026-05-16', NULL),
  (32, 'Metformina 850mg', 'conforme bula', '1 comprimido apos o almoco', 30, 30, '2026-06-10', NULL),
  (33, 'Loratadina 10mg', 'conforme bula', '1 comprimido ao dia', 10, 30, '2026-06-08', NULL),
  (34, 'Losartana 50mg', 'conforme bula', '1 comprimido pela manha', 10, 10, '2026-06-11', NULL),
  (36, 'Metformina 850mg', 'conforme bula', '1 comprimido apos o almoco', 30, 15, '2026-02-02', NULL),
  (37, 'Paracetamol 750mg', 'conforme bula', '1 comprimido a cada 8 horas', 30, 15, '2026-07-29', NULL),
  (37, 'Omeprazol 20mg', 'conforme bula', '1 capsula em jejum', 10, 7, '2026-07-29', NULL),
  (39, 'Diazepam 5mg', 'conforme bula', '1 comprimido antes de dormir', 10, 10, '2026-08-23', NULL),
  (40, 'Ibuprofeno 600mg', 'conforme bula', '1 comprimido a cada 12 horas', 10, 5, '2026-07-28', NULL),
  (40, 'Ibuprofeno 600mg', 'conforme bula', '1 comprimido a cada 12 horas', 10, 7, '2026-07-28', NULL),
  (41, 'Metformina 850mg', 'conforme bula', '1 comprimido apos o almoco', 30, 7, '2026-02-11', NULL),
  (42, 'Losartana 50mg', 'conforme bula', '1 comprimido pela manha', 10, 5, '2026-06-27', NULL),
  (42, 'Amoxicilina 500mg', 'conforme bula', '1 capsula a cada 8 horas', 60, 10, '2026-06-27', NULL),
  (43, 'Diazepam 5mg', 'conforme bula', '1 comprimido antes de dormir', 10, 15, '2026-01-18', NULL),
  (44, 'Dipirona 500mg', 'conforme bula', '1 comprimido a cada 6 horas', 60, 30, '2026-06-26', NULL),
  (47, 'Paracetamol 750mg', 'conforme bula', '1 comprimido a cada 8 horas', 20, 30, '2026-04-30', NULL),
  (47, 'Dipirona 500mg', 'conforme bula', '1 comprimido a cada 6 horas', 10, 5, '2026-04-30', NULL),
  (49, 'Ibuprofeno 600mg', 'conforme bula', '1 comprimido a cada 12 horas', 20, 5, '2026-07-17', NULL),
  (50, 'Loratadina 10mg', 'conforme bula', '1 comprimido ao dia', 20, 10, '2026-08-12', NULL),
  (50, 'Omeprazol 20mg', 'conforme bula', '1 capsula em jejum', 60, 10, '2026-08-12', NULL),
  (53, 'Dipirona 500mg', 'conforme bula', '1 comprimido a cada 6 horas', 20, 7, '2026-01-15', NULL),
  (53, 'Metformina 850mg', 'conforme bula', '1 comprimido apos o almoco', 10, 15, '2026-01-15', NULL),
  (55, 'Losartana 50mg', 'conforme bula', '1 comprimido pela manha', 30, 5, '2026-04-01', NULL),
  (56, 'Amoxicilina 500mg', 'conforme bula', '1 capsula a cada 8 horas', 20, 10, '2026-01-04', NULL),
  (57, 'Diazepam 5mg', 'conforme bula', '1 comprimido antes de dormir', 20, 15, '2025-12-01', NULL),
  (58, 'Omeprazol 20mg', 'conforme bula', '1 capsula em jejum', 20, 7, '2025-11-19', NULL),
  (60, 'Metformina 850mg', 'conforme bula', '1 comprimido apos o almoco', 30, 5, '2026-03-09', NULL),
  (61, 'Loratadina 10mg', 'conforme bula', '1 comprimido ao dia', 30, 5, '2025-12-16', NULL),
  (63, 'Sinvastatina 20mg', 'conforme bula', '1 comprimido a noite', 10, 7, '2026-08-23', NULL),
  (64, 'Dipirona 500mg', 'conforme bula', '1 comprimido a cada 6 horas', 20, 30, '2026-01-07', NULL),
  (65, 'Sinvastatina 20mg', 'conforme bula', '1 comprimido a noite', 10, 30, '2025-11-16', NULL),
  (68, 'Diazepam 5mg', 'conforme bula', '1 comprimido antes de dormir', 10, 15, '2026-03-08', NULL),
  (69, 'Omeprazol 20mg', 'conforme bula', '1 capsula em jejum', 30, 10, '2026-08-24', NULL),
  (70, 'Amoxicilina 500mg', 'conforme bula', '1 capsula a cada 8 horas', 30, 15, '2025-12-18', NULL),
  (74, 'Paracetamol 750mg', 'conforme bula', '1 comprimido a cada 8 horas', 20, 5, '2026-06-04', NULL),
  (74, 'Ibuprofeno 600mg', 'conforme bula', '1 comprimido a cada 12 horas', 60, 15, '2026-06-04', NULL),
  (77, 'Sinvastatina 20mg', 'conforme bula', '1 comprimido a noite', 30, 15, '2026-03-24', NULL),
  (81, 'Diazepam 5mg', 'conforme bula', '1 comprimido antes de dormir', 10, 7, '2026-03-01', NULL),
  (81, 'Amoxicilina 500mg', 'conforme bula', '1 capsula a cada 8 horas', 20, 5, '2026-03-01', NULL),
  (82, 'Loratadina 10mg', 'conforme bula', '1 comprimido ao dia', 10, 10, '2026-08-22', NULL),
  (84, 'Loratadina 10mg', 'conforme bula', '1 comprimido ao dia', 60, 30, '2026-06-22', NULL),
  (85, 'Paracetamol 750mg', 'conforme bula', '1 comprimido a cada 8 horas', 60, 5, '2026-01-30', NULL),
  (86, 'Paracetamol 750mg', 'conforme bula', '1 comprimido a cada 8 horas', 10, 5, '2026-04-16', NULL),
  (87, 'Ibuprofeno 600mg', 'conforme bula', '1 comprimido a cada 12 horas', 20, 15, '2026-06-02', NULL),
  (88, 'Paracetamol 750mg', 'conforme bula', '1 comprimido a cada 8 horas', 30, 5, '2026-08-22', NULL),
  (88, 'Dipirona 500mg', 'conforme bula', '1 comprimido a cada 6 horas', 10, 7, '2026-08-22', NULL),
  (89, 'Ibuprofeno 600mg', 'conforme bula', '1 comprimido a cada 12 horas', 10, 10, '2026-07-21', NULL),
  (91, 'Ibuprofeno 600mg', 'conforme bula', '1 comprimido a cada 12 horas', 60, 15, '2026-08-06', NULL),
  (92, 'Loratadina 10mg', 'conforme bula', '1 comprimido ao dia', 20, 10, '2026-06-05', NULL),
  (96, 'Diazepam 5mg', 'conforme bula', '1 comprimido antes de dormir', 20, 10, '2026-08-23', NULL),
  (97, 'Sinvastatina 20mg', 'conforme bula', '1 comprimido a noite', 10, 5, '2026-06-01', NULL),
  (97, 'Losartana 50mg', 'conforme bula', '1 comprimido pela manha', 60, 7, '2026-06-01', NULL),
  (98, 'Metformina 850mg', 'conforme bula', '1 comprimido apos o almoco', 20, 30, '2025-11-26', NULL),
  (98, 'Dipirona 500mg', 'conforme bula', '1 comprimido a cada 6 horas', 60, 10, '2025-11-26', NULL),
  (99, 'Amoxicilina 500mg', 'conforme bula', '1 capsula a cada 8 horas', 30, 15, '2026-02-04', NULL),
  (102, 'Losartana 50mg', 'conforme bula', '1 comprimido pela manha', 10, 15, '2026-05-15', NULL),
  (103, 'Omeprazol 20mg', 'conforme bula', '1 capsula em jejum', 20, 5, '2026-04-14', NULL),
  (103, 'Omeprazol 20mg', 'conforme bula', '1 capsula em jejum', 20, 10, '2026-04-14', NULL),
  (104, 'Dipirona 500mg', 'conforme bula', '1 comprimido a cada 6 horas', 20, 30, '2026-03-13', NULL),
  (104, 'Loratadina 10mg', 'conforme bula', '1 comprimido ao dia', 30, 7, '2026-03-13', NULL);

-- ============================================================
-- Inserção de dados — pagamentos
-- ============================================================

INSERT INTO pagamentos (id_consulta, valor, data_pagamento, metodo_pagamento, status_pagamento, numero_recibo, data_vencimento, observacoes) VALUES
  (2, 275.24, '2026-03-06', 'Pix', 'Pago', 'REC-000001', '2026-03-16', NULL),
  (4, 204.42, NULL, NULL, 'Pendente', NULL, '2026-06-29', NULL),
  (6, 159.43, '2026-08-24', 'Pix', 'Pago', 'REC-000002', '2026-09-08', NULL),
  (8, 227.26, NULL, NULL, 'Cancelado', NULL, '2026-05-04', NULL),
  (9, 232.31, '2026-04-25', 'Cartao', 'Pago', 'REC-000003', '2026-05-01', NULL),
  (10, 272.28, NULL, NULL, 'Cancelado', NULL, '2026-06-16', NULL),
  (12, 212.36, '2026-01-25', 'Pix', 'Pago', 'REC-000004', '2026-02-06', NULL),
  (13, 204.12, NULL, NULL, 'Pendente', NULL, '2026-07-30', NULL),
  (14, 291.16, NULL, NULL, 'Cancelado', NULL, '2026-06-01', NULL),
  (16, 339.96, NULL, NULL, 'Pendente', NULL, '2026-05-12', NULL),
  (17, 322.89, NULL, NULL, 'Pendente', NULL, '2026-03-16', NULL),
  (18, 226.09, '2026-07-20', 'Dinheiro', 'Pago', 'REC-000005', '2026-07-28', NULL),
  (19, 265.92, '2026-08-01', 'Dinheiro', 'Pago', 'REC-000006', '2026-08-13', NULL),
  (20, 300.53, '2026-05-02', 'Dinheiro', 'Pago', 'REC-000007', '2026-05-09', NULL),
  (22, 259.04, '2026-06-21', 'Cartao', 'Pago', 'REC-000008', '2026-06-27', NULL),
  (23, 224.73, '2026-04-22', 'Dinheiro', 'Pago', 'REC-000009', '2026-05-02', NULL),
  (24, 284.83, '2026-01-28', 'Cartao', 'Pago', 'REC-000010', '2026-02-12', NULL),
  (25, 160.01, '2026-03-02', 'Pix', 'Pago', 'REC-000011', '2026-03-15', NULL),
  (26, 262.32, NULL, NULL, 'Cancelado', NULL, '2025-12-24', NULL),
  (27, 287.02, '2026-05-22', 'Pix', 'Pago', 'REC-000012', '2026-06-01', NULL),
  (28, 317.43, NULL, NULL, 'Pendente', NULL, '2026-06-07', NULL),
  (29, 265.31, NULL, NULL, 'Cancelado', NULL, '2026-04-12', NULL),
  (31, 180.7, NULL, NULL, 'Cancelado', NULL, '2026-01-23', NULL),
  (33, 258.23, '2026-01-05', 'Pix', 'Pago', 'REC-000013', '2026-01-14', NULL),
  (34, 273.7, '2025-12-22', 'Cartao', 'Pago', 'REC-000014', '2026-01-02', NULL),
  (35, 170.37, '2026-01-02', 'Dinheiro', 'Pago', 'REC-000015', '2026-01-11', NULL),
  (37, 168.1, '2026-07-22', 'Cartao', 'Pago', 'REC-000016', '2026-07-27', NULL),
  (38, 310.36, '2026-09-06', 'Pix', 'Pago', 'REC-000017', '2026-09-13', NULL),
  (39, 323.02, '2026-05-15', 'Pix', 'Pago', 'REC-000018', '2026-05-25', NULL),
  (40, 238.82, '2025-12-05', 'Pix', 'Pago', 'REC-000019', '2025-12-18', NULL),
  (41, 285.39, '2025-12-01', 'Pix', 'Pago', 'REC-000020', '2025-12-12', NULL),
  (42, 310.52, '2026-01-16', 'Pix', 'Pago', 'REC-000021', '2026-01-31', NULL),
  (43, 216.95, NULL, NULL, 'Pendente', NULL, '2025-11-24', NULL),
  (44, 306.46, NULL, NULL, 'Pendente', NULL, '2026-08-13', NULL),
  (45, 274.56, '2026-07-26', 'Pix', 'Pago', 'REC-000022', '2026-08-10', NULL),
  (46, 234.27, '2026-07-20', 'Cartao', 'Pago', 'REC-000023', '2026-07-26', NULL),
  (47, 138.72, '2026-05-17', 'Pix', 'Pago', 'REC-000024', '2026-05-31', NULL),
  (48, 254.58, NULL, NULL, 'Pendente', NULL, '2026-06-25', NULL),
  (49, 187.63, '2026-06-09', 'Pix', 'Pago', 'REC-000025', '2026-06-23', NULL),
  (50, 207.82, '2026-06-13', 'Cartao', 'Pago', 'REC-000026', '2026-06-26', NULL),
  (51, 212.96, '2026-06-16', 'Dinheiro', 'Pago', 'REC-000027', '2026-06-21', NULL),
  (52, 272.66, NULL, NULL, 'Cancelado', NULL, '2026-01-11', NULL),
  (54, 196.45, '2026-02-09', 'Cartao', 'Pago', 'REC-000028', '2026-02-17', NULL),
  (58, 188.97, '2026-08-01', 'Dinheiro', 'Pago', 'REC-000029', '2026-08-13', NULL),
  (60, 236.75, '2026-07-20', 'Cartao', 'Pago', 'REC-000030', '2026-07-31', NULL),
  (61, 200.88, '2026-08-23', 'Pix', 'Pago', 'REC-000031', '2026-09-07', NULL),
  (63, 171.97, '2026-08-03', 'Cartao', 'Pago', 'REC-000032', '2026-08-12', NULL),
  (65, 234.05, NULL, NULL, 'Pendente', NULL, '2026-02-26', NULL),
  (66, 171.99, NULL, NULL, 'Pendente', NULL, '2026-07-12', NULL),
  (67, 146.36, '2026-01-23', 'Cartao', 'Pago', 'REC-000033', '2026-02-02', NULL),
  (69, 196.08, '2026-07-03', 'Dinheiro', 'Pago', 'REC-000034', '2026-07-11', NULL),
  (70, 169.77, '2026-01-03', 'Pix', 'Pago', 'REC-000035', '2026-01-08', NULL),
  (71, 273.4, NULL, NULL, 'Cancelado', NULL, '2026-05-22', NULL),
  (72, 145.66, '2025-12-07', 'Dinheiro', 'Pago', 'REC-000036', '2025-12-20', NULL),
  (73, 157.31, '2026-05-04', 'Dinheiro', 'Pago', 'REC-000037', '2026-05-15', NULL),
  (74, 227.81, NULL, NULL, 'Cancelado', NULL, '2026-01-21', NULL),
  (76, 245.75, NULL, NULL, 'Cancelado', NULL, '2026-05-08', NULL),
  (77, 195.68, NULL, NULL, 'Cancelado', NULL, '2026-05-22', NULL),
  (78, 343.83, '2026-07-01', 'Cartao', 'Pago', 'REC-000038', '2026-07-15', NULL),
  (79, 252.34, '2026-07-23', 'Dinheiro', 'Pago', 'REC-000039', '2026-08-01', NULL),
  (80, 291.38, '2026-08-20', 'Dinheiro', 'Pago', 'REC-000040', '2026-08-27', NULL),
  (81, 291.5, NULL, NULL, 'Pendente', NULL, '2026-06-28', NULL),
  (82, 225.32, NULL, NULL, 'Pendente', NULL, '2026-03-17', NULL),
  (83, 152.72, '2026-01-22', 'Pix', 'Pago', 'REC-000041', '2026-01-30', NULL),
  (90, 231.6, '2026-02-09', 'Cartao', 'Pago', 'REC-000042', '2026-02-14', NULL),
  (91, 244.72, '2026-04-03', 'Cartao', 'Pago', 'REC-000043', '2026-04-16', NULL),
  (93, 235.97, '2026-01-07', 'Cartao', 'Pago', 'REC-000044', '2026-01-19', NULL),
  (96, 312.9, NULL, NULL, 'Cancelado', NULL, '2026-02-10', NULL),
  (97, 236.5, NULL, NULL, 'Pendente', NULL, '2025-12-16', NULL),
  (98, 218.15, '2025-11-27', 'Pix', 'Pago', 'REC-000045', '2025-12-04', NULL),
  (99, 250.44, '2026-06-24', 'Cartao', 'Pago', 'REC-000046', '2026-07-05', NULL),
  (100, 149.51, '2026-03-15', 'Dinheiro', 'Pago', 'REC-000047', '2026-03-24', NULL),
  (102, 290.5, '2025-12-18', 'Cartao', 'Pago', 'REC-000048', '2025-12-31', NULL),
  (103, 211.02, '2026-05-12', 'Dinheiro', 'Pago', 'REC-000049', '2026-05-21', NULL),
  (105, 273.37, '2026-09-02', 'Pix', 'Pago', 'REC-000050', '2026-09-07', NULL),
  (106, 277.97, '2026-01-08', 'Dinheiro', 'Pago', 'REC-000051', '2026-01-22', NULL),
  (107, 222.34, NULL, NULL, 'Cancelado', NULL, '2026-05-13', NULL),
  (108, 308.76, NULL, NULL, 'Cancelado', NULL, '2026-08-01', NULL),
  (109, 144.92, '2025-11-26', 'Dinheiro', 'Pago', 'REC-000052', '2025-12-01', NULL),
  (110, 275.29, NULL, NULL, 'Cancelado', NULL, '2026-07-29', NULL),
  (111, 197.01, '2026-01-28', 'Dinheiro', 'Pago', 'REC-000053', '2026-02-05', NULL),
  (112, 259.43, NULL, NULL, 'Pendente', NULL, '2026-05-12', NULL),
  (113, 268.93, '2026-03-15', 'Cartao', 'Pago', 'REC-000054', '2026-03-23', NULL),
  (114, 226.31, '2026-08-28', 'Pix', 'Pago', 'REC-000055', '2026-09-08', NULL),
  (115, 238.45, '2025-12-24', 'Pix', 'Pago', 'REC-000056', '2026-01-02', NULL),
  (117, 280.92, NULL, NULL, 'Cancelado', NULL, '2026-06-11', NULL),
  (118, 229.45, NULL, NULL, 'Cancelado', NULL, '2026-08-02', NULL),
  (119, 189.95, '2026-05-17', 'Cartao', 'Pago', 'REC-000057', '2026-05-27', NULL),
  (120, 224.94, '2026-01-15', 'Dinheiro', 'Pago', 'REC-000058', '2026-01-26', NULL),
  (121, 184.83, '2026-01-27', 'Cartao', 'Pago', 'REC-000059', '2026-02-08', NULL),
  (122, 271.12, NULL, NULL, 'Cancelado', NULL, '2025-11-25', NULL),
  (124, 187.77, NULL, NULL, 'Cancelado', NULL, '2026-02-12', NULL),
  (125, 328.12, NULL, NULL, 'Pendente', NULL, '2026-06-19', NULL),
  (126, 285.49, '2026-01-21', 'Dinheiro', 'Pago', 'REC-000060', '2026-01-26', NULL),
  (127, 245.72, '2026-08-06', 'Pix', 'Pago', 'REC-000061', '2026-08-16', NULL),
  (128, 322.87, NULL, NULL, 'Pendente', NULL, '2026-04-08', NULL),
  (129, 236.03, '2026-04-01', 'Pix', 'Pago', 'REC-000062', '2026-04-13', NULL),
  (130, 272.86, '2026-04-07', 'Cartao', 'Pago', 'REC-000063', '2026-04-14', NULL),
  (131, 280.3, '2026-08-14', 'Pix', 'Pago', 'REC-000064', '2026-08-19', NULL),
  (132, 234.16, NULL, NULL, 'Pendente', NULL, '2026-03-16', NULL),
  (134, 226.5, '2026-08-29', 'Dinheiro', 'Pago', 'REC-000065', '2026-09-06', NULL),
  (135, 162.42, '2026-07-13', 'Cartao', 'Pago', 'REC-000066', '2026-07-28', NULL),
  (136, 213.57, '2026-07-01', 'Pix', 'Pago', 'REC-000067', '2026-07-07', NULL),
  (138, 248.85, '2026-02-01', 'Pix', 'Pago', 'REC-000068', '2026-02-14', NULL),
  (139, 222.57, '2026-04-18', 'Cartao', 'Pago', 'REC-000069', '2026-05-01', NULL),
  (141, 170.9, NULL, NULL, 'Cancelado', NULL, '2026-01-16', NULL),
  (142, 309.79, NULL, NULL, 'Pendente', NULL, '2026-06-17', NULL),
  (144, 262.72, '2026-08-25', 'Dinheiro', 'Pago', 'REC-000070', '2026-09-06', NULL),
  (145, 257.08, '2026-07-22', 'Cartao', 'Pago', 'REC-000071', '2026-08-05', NULL),
  (146, 271.61, NULL, NULL, 'Pendente', NULL, '2026-04-23', NULL),
  (147, 213.78, '2026-08-08', 'Pix', 'Pago', 'REC-000072', '2026-08-21', NULL),
  (148, 304.91, NULL, NULL, 'Pendente', NULL, '2026-06-20', NULL),
  (149, 214.32, '2026-04-30', 'Pix', 'Pago', 'REC-000073', '2026-05-14', NULL),
  (150, 268.6, '2026-04-09', 'Pix', 'Pago', 'REC-000074', '2026-04-18', NULL),
  (153, 196.92, '2026-06-22', 'Cartao', 'Pago', 'REC-000075', '2026-06-29', NULL),
  (154, 320.33, '2026-09-01', 'Dinheiro', 'Pago', 'REC-000076', '2026-09-07', NULL),
  (155, 230.54, '2026-06-02', 'Cartao', 'Pago', 'REC-000077', '2026-06-16', NULL),
  (156, 237.16, '2025-12-05', 'Dinheiro', 'Pago', 'REC-000078', '2025-12-11', NULL),
  (157, 290.76, '2026-02-05', 'Dinheiro', 'Pago', 'REC-000079', '2026-02-19', NULL),
  (159, 220.76, '2026-08-07', 'Dinheiro', 'Pago', 'REC-000080', '2026-08-18', NULL),
  (160, 338.17, NULL, NULL, 'Cancelado', NULL, '2026-07-20', NULL),
  (161, 279.76, NULL, NULL, 'Pendente', NULL, '2026-07-20', NULL),
  (162, 260.66, NULL, NULL, 'Pendente', NULL, '2026-05-30', NULL),
  (163, 280.97, NULL, NULL, 'Pendente', NULL, '2026-04-29', NULL),
  (165, 152.28, '2026-03-20', 'Pix', 'Pago', 'REC-000081', '2026-03-28', NULL);
-- ================================================================
-- DML — Atualizações (UPDATE)
-- ================================================================

-- 1) Cancela a consulta agendada mais próxima, simulando um cancelamento
--    solicitado pelo paciente
UPDATE consultas
SET status = 'Cancelada', observacoes = 'Cancelado a pedido do paciente'
WHERE status = 'Agendada'
ORDER BY data_consulta ASC, hora_consulta ASC
LIMIT 1;

-- 2) Reajuste de 5% no valor base da especialidade de Cardiologia
UPDATE especialidades
SET valor_base = ROUND(valor_base * 1.05, 2)
WHERE nome_especialidade = 'Cardiologia';

-- 3) Quita pagamentos pendentes com vencimento há mais de 60 dias,
--    simulando uma cobrança que resultou em pagamento via Pix
UPDATE pagamentos
SET status_pagamento = 'Pago', metodo_pagamento = 'Pix', data_pagamento = CURDATE()
WHERE status_pagamento = 'Pendente'
  AND data_vencimento < (CURDATE() - INTERVAL 60 DAY)
LIMIT 3;

-- 4) Marca o médico mais recentemente cadastrado como inativo
--    (exemplo de afastamento/licença)
UPDATE medicos
SET status_ativo = FALSE
ORDER BY data_cadastro DESC
LIMIT 1;

-- ================================================================
-- DQL — Consultas de agregação (mínimo 4, variando funções)
-- ================================================================

-- A1) COUNT — quantidade de pacientes por convênio/plano
SELECT
    c.nome AS convenio,
    COUNT(p.id_paciente) AS total_pacientes
FROM convenios c
LEFT JOIN pacientes p ON p.id_convenio = c.id_convenio
GROUP BY c.nome
ORDER BY total_pacientes DESC;

-- A2) AVG — valor médio cobrado por consulta, por especialidade
SELECT
    e.nome_especialidade,
    ROUND(AVG(co.valor), 2) AS valor_medio_consulta
FROM consultas co
JOIN especialidades e ON e.id_especialidade = co.id_especialidade
GROUP BY e.nome_especialidade
ORDER BY valor_medio_consulta DESC;

-- A3) SUM — faturamento total (pagamentos com status 'Pago') por médico
SELECT
    m.nome_completo AS medico,
    COALESCE(SUM(pg.valor), 0) AS faturamento_total
FROM medicos m
JOIN consultas co ON co.id_medico = m.id_medico
JOIN pagamentos pg ON pg.id_consulta = co.id_consulta AND pg.status_pagamento = 'Pago'
GROUP BY m.nome_completo
ORDER BY faturamento_total DESC;

-- A4) MAX / MIN — maior e menor valor de consulta praticado por especialidade
SELECT
    e.nome_especialidade,
    MAX(co.valor) AS maior_valor,
    MIN(co.valor) AS menor_valor
FROM consultas co
JOIN especialidades e ON e.id_especialidade = co.id_especialidade
GROUP BY e.nome_especialidade
ORDER BY e.nome_especialidade;

-- A5) COUNT + HAVING — taxa de no-show por especialidade (consultas que já deveriam ter ocorrido)
SELECT
    e.nome_especialidade,
    COUNT(*) AS total_consultas_passadas,
    SUM(CASE WHEN co.status = 'Faltou' THEN 1 ELSE 0 END) AS total_faltas,
    ROUND(100 * SUM(CASE WHEN co.status = 'Faltou' THEN 1 ELSE 0 END) / COUNT(*), 1) AS taxa_no_show_pct
FROM consultas co
JOIN especialidades e ON e.id_especialidade = co.id_especialidade
WHERE co.status IN ('Realizada', 'Faltou', 'Cancelada')
GROUP BY e.nome_especialidade
HAVING total_consultas_passadas >= 3
ORDER BY taxa_no_show_pct DESC;


-- ================================================================
-- DQL — Consultas com JOIN (mínimo 4, variando o tipo)
-- ================================================================

-- J1) INNER JOIN — pacientes com médico, especialidade, data e status de cada consulta
SELECT
    p.nome_completo AS paciente,
    m.nome_completo AS medico,
    e.nome_especialidade AS especialidade,
    co.data_consulta,
    co.status
FROM pacientes p
INNER JOIN consultas co ON co.id_paciente = p.id_paciente
INNER JOIN medicos m ON m.id_medico = co.id_medico
INNER JOIN especialidades e ON e.id_especialidade = co.id_especialidade
ORDER BY p.nome_completo, co.data_consulta;

-- J2) LEFT JOIN — pacientes e total de consultas (inclui quem tem 0)
SELECT
    p.nome_completo AS paciente,
    COUNT(co.id_consulta) AS total_consultas
FROM pacientes p
LEFT JOIN consultas co ON co.id_paciente = p.id_paciente
GROUP BY p.nome_completo
ORDER BY total_consultas DESC;

-- J3) RIGHT JOIN — especialidades e suas consultas (inclui especialidades sem nenhuma)
SELECT
    e.nome_especialidade,
    co.id_consulta,
    co.data_consulta,
    co.status
FROM consultas co
RIGHT JOIN especialidades e ON e.id_especialidade = co.id_especialidade
ORDER BY e.nome_especialidade;

-- J4) FULL JOIN — MySQL não tem FULL JOIN nativo; equivalente via UNION de LEFT JOIN + RIGHT JOIN
SELECT m.nome_completo AS medico, esp.nome_especialidade AS especialidade
FROM medicos m
LEFT JOIN medico_especialidade me ON me.id_medico = m.id_medico
LEFT JOIN especialidades esp ON esp.id_especialidade = me.id_especialidade
UNION
SELECT m.nome_completo AS medico, esp.nome_especialidade AS especialidade
FROM medicos m
RIGHT JOIN medico_especialidade me ON me.id_medico = m.id_medico
RIGHT JOIN especialidades esp ON esp.id_especialidade = me.id_especialidade
ORDER BY medico;

-- J5) INNER JOIN (múltiplos níveis) — prescrições com informações do paciente
SELECT
    pa.nome_completo AS paciente,
    pr.medicamento,
    pr.posologia,
    pr.data_prescricao
FROM prescricoes pr
INNER JOIN evolucoes ev ON ev.id_evolucao = pr.id_evolucao
INNER JOIN consultas co ON co.id_consulta = ev.id_consulta
INNER JOIN pacientes pa ON pa.id_paciente = co.id_paciente
ORDER BY pr.data_prescricao DESC;
