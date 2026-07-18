<?php

namespace App\Repositories;

class CompanyRepository extends BaseRepository {
    protected function getTableName(): string {
        return 'companies';
    }
}
