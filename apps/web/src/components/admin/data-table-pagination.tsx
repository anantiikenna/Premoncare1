'use client'

import { Button } from '@/components/ui/button'
import { ChevronLeft, ChevronRight } from 'lucide-react'

interface DataTablePaginationProps {
    currentPage: number
    totalPages: number
    totalItems: number
    pageSize: number
    onPageChange: (page: number) => void
}

export function DataTablePagination({ currentPage, totalPages, totalItems, pageSize, onPageChange }: DataTablePaginationProps) {
    if (totalPages <= 1) return null

    const startItem = (currentPage - 1) * pageSize + 1
    const endItem = Math.min(currentPage * pageSize, totalItems)

    return (
        <div className="flex items-center justify-between px-2 py-4">
            <p className="text-sm text-muted-foreground">
                Showing {startItem}–{endItem} of {totalItems}
            </p>
            <div className="flex items-center gap-2">
                <Button
                    variant="outline"
                    size="sm"
                    onClick={() => onPageChange(currentPage - 1)}
                    disabled={currentPage <= 1}
                    className="cursor-pointer"
                >
                    <ChevronLeft className="h-4 w-4" />
                </Button>
                {Array.from({ length: Math.min(5, totalPages) }, (_, i) => {
                    let page: number
                    if (totalPages <= 5) {
                        page = i + 1
                    } else if (currentPage <= 3) {
                        page = i + 1
                    } else if (currentPage >= totalPages - 2) {
                        page = totalPages - 4 + i
                    } else {
                        page = currentPage - 2 + i
                    }
                    return (
                        <Button
                            key={page}
                            variant={page === currentPage ? 'default' : 'outline'}
                            size="sm"
                            className={`w-9 h-9 cursor-pointer ${page === currentPage ? 'bg-primary text-primary-foreground' : ''}`}
                            onClick={() => onPageChange(page)}
                        >
                            {page}
                        </Button>
                    )
                })}
                <Button
                    variant="outline"
                    size="sm"
                    onClick={() => onPageChange(currentPage + 1)}
                    disabled={currentPage >= totalPages}
                    className="cursor-pointer"
                >
                    <ChevronRight className="h-4 w-4" />
                </Button>
            </div>
        </div>
    )
}
